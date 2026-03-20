/**
 * RemoteSelect - Vanilla JS remote data select component
 * A lightweight replacement for select2/tom-select with remote data source
 * 
 * Features:
 * - Remote data fetching with debouncing
 * - Pagination support
 * - Dynamic parameters (e.g., dependent selects)
 * - Minimum character threshold
 * - Preselected values
 * - No jQuery dependency
 */
class RemoteSelect {
  constructor(element, options = {}) {
    this.element = element;
    const ds = element.dataset;

    // Options: JS options take precedence over data attributes, falling back to defaults.
    // The object is built explicitly — no spread of raw `options` after parsed values,
    // which would silently re-override the carefully resolved types below.
    this.options = {
      endpoint:                options.endpoint                ?? ds.endpoint,
      minChars:                parseInt(options.minChars       ?? ds.minChars       ?? 2,   10),
      debounceDelay:           parseInt(options.debounceDelay  ?? ds.debounceDelay  ?? 250, 10),
      placeholder:             options.placeholder             ?? ds.placeholder             ?? 'Type to search...',
      perPage:                 parseInt(options.perPage        ?? ds.perPage        ?? 20,  10),
      dependsOn:               options.dependsOn               ?? ds.dependsOn               ?? null,
      clearOnDependencyChange: _parseBool(options.clearOnDependencyChange ?? ds.clearOnDependencyChange, true),
      emptyText:               options.emptyText               ?? ds.emptyText               ?? 'No results found',
      loadingText:             options.loadingText             ?? ds.loadingText              ?? 'Loading...',
    };

    this.selectedValue       = ds.selectedValue || '';
    this.selectedText        = ds.selectedText  || '';
    this.currentQuery        = '';
    this.currentPage         = 1;
    this.hasMore             = false;
    this.loading             = false;
    this.debounceTimer       = null;
    this.results             = [];
    this.additionalParams    = {};
    this.focusedIndex        = -1;
    this._abortController    = null;
    this._dependencyHandlers = [];
    // Unique ID prefix for ARIA id references
    this._uid = `rs-${Math.random().toString(36).slice(2, 9)}`;

    this._init();
  }

  _init() {
    this.element.style.display = 'none';
    this._createUI();
    this._setupEventListeners();
    if (this.options.dependsOn) this._setupDependency();
    if (this.selectedValue && this.selectedText) this._updateTriggerDisplay();
  }

  _createUI() {
    this.container = document.createElement('div');
    this.container.className = 'remote-select-container';

    // Trigger — acts as the visible combobox control
    this.trigger = document.createElement('div');
    this.trigger.className = 'remote-select-trigger';
    this.trigger.setAttribute('tabindex', '0');
    this.trigger.setAttribute('role', 'combobox');
    this.trigger.setAttribute('aria-expanded', 'false');
    this.trigger.setAttribute('aria-haspopup', 'listbox');
    this.trigger.setAttribute('aria-controls', `${this._uid}-listbox`);

    this.valueSpan = document.createElement('span');
    this.valueSpan.className = 'remote-select-value';
    this.valueSpan.textContent = this.selectedText || this.options.placeholder;
    this.trigger.appendChild(this.valueSpan);

    // Dropdown
    this.dropdown = document.createElement('div');
    this.dropdown.className = 'remote-select-dropdown';
    this.dropdown.id = `${this._uid}-listbox`;
    this.dropdown.setAttribute('role', 'listbox');

    // Search input inside dropdown
    this.searchInput = document.createElement('input');
    this.searchInput.type = 'text';
    this.searchInput.className = 'remote-select-search';
    this.searchInput.placeholder = this.options.placeholder;
    this.searchInput.setAttribute('autocomplete', 'off');
    this.searchInput.setAttribute('aria-autocomplete', 'list');
    this.searchInput.setAttribute('aria-controls', `${this._uid}-listbox`);

    // Results container
    this.resultsContainer = document.createElement('div');
    this.resultsContainer.className = 'remote-select-results';

    this.dropdown.appendChild(this.searchInput);
    this.dropdown.appendChild(this.resultsContainer);
    this.container.appendChild(this.trigger);
    this.container.appendChild(this.dropdown);

    this.element.parentNode.insertBefore(this.container, this.element.nextSibling);
  }

  _setupEventListeners() {
    // Open/close via click on trigger
    this.trigger.addEventListener('click', (e) => {
      e.stopPropagation();
      this.toggleDropdown();
    });

    // Keyboard activation of trigger (Space/Enter opens; ArrowDown opens and moves focus)
    this.trigger.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        this.openDropdown();
      } else if (e.key === 'ArrowDown') {
        e.preventDefault();
        this.openDropdown();
      }
    });

    // Search input typing
    this.searchInput.addEventListener('input', (e) => {
      this._handleSearchInput(e.target.value);
    });

    // Keyboard navigation within dropdown
    this.searchInput.addEventListener('keydown', (e) => {
      this._handleKeyboardNavigation(e);
    });

    // Infinite scroll pagination
    this.resultsContainer.addEventListener('scroll', () => {
      if (this._isScrolledToBottom() && this.hasMore && !this.loading) {
        this.currentPage++;
        this._fetchResults(this.currentQuery, true);
      }
    });

    // Close on outside click — stored as named ref for cleanup in destroy()
    this._outsideClickHandler = (e) => {
      if (!this.container.contains(e.target)) this.closeDropdown();
    };
    document.addEventListener('click', this._outsideClickHandler);
  }

  _handleKeyboardNavigation(e) {
    const items = Array.from(this.resultsContainer.querySelectorAll('.remote-select-item'));
    if (!items.length) {
      if (e.key === 'Escape') { this.closeDropdown(); this.trigger.focus(); }
      return;
    }

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        this._setFocusedIndex(Math.min(this.focusedIndex + 1, items.length - 1), items);
        break;
      case 'ArrowUp':
        e.preventDefault();
        if (this.focusedIndex <= 0) {
          this._setFocusedIndex(-1, items);
        } else {
          this._setFocusedIndex(this.focusedIndex - 1, items);
        }
        break;
      case 'Enter':
        e.preventDefault();
        if (this.focusedIndex >= 0 && items[this.focusedIndex]) {
          items[this.focusedIndex].click();
        }
        break;
      case 'Escape':
        this.closeDropdown();
        this.trigger.focus();
        break;
    }
  }

  _setFocusedIndex(newIndex, items) {
    // Remove highlight from previously focused item
    if (this.focusedIndex >= 0 && items[this.focusedIndex]) {
      items[this.focusedIndex].classList.remove('is-focused');
      items[this.focusedIndex].setAttribute('aria-selected', 'false');
    }

    this.focusedIndex = newIndex;

    if (newIndex >= 0 && items[newIndex]) {
      items[newIndex].classList.add('is-focused');
      items[newIndex].setAttribute('aria-selected', 'true');
      items[newIndex].scrollIntoView({ block: 'nearest' });
      this.trigger.setAttribute('aria-activedescendant', items[newIndex].id);
      this.searchInput.setAttribute('aria-activedescendant', items[newIndex].id);
    } else {
      this.trigger.removeAttribute('aria-activedescendant');
      this.searchInput.removeAttribute('aria-activedescendant');
    }
  }

  _setupDependency() {
    this.options.dependsOn.split(',').map(s => s.trim()).forEach(selector => {
      const depEl = document.querySelector(selector);
      if (!depEl) return;

      const handler = (e) => {
        const key = depEl.name || depEl.id;
        this.additionalParams[key] = e.target.value;
        if (this.options.clearOnDependencyChange) this.clearSelection();
      };

      depEl.addEventListener('change', handler);
      this._dependencyHandlers.push({ element: depEl, handler });

      // Set initial param value
      const key = depEl.name || depEl.id;
      this.additionalParams[key] = depEl.value;
    });
  }

  _handleSearchInput(query) {
    clearTimeout(this.debounceTimer);
    this.currentQuery = query;
    this.currentPage  = 1;
    this.focusedIndex = -1;

    if (query.length < this.options.minChars) {
      this._setMessage(this.options.placeholder);
      return;
    }

    this.debounceTimer = setTimeout(() => {
      this._fetchResults(query, false);
    }, this.options.debounceDelay);
  }

  async _fetchResults(query, append = false) {
    if (this.loading) return;

    // Cancel any in-flight request so stale results cannot overwrite the current query
    if (this._abortController) this._abortController.abort();
    this._abortController = new AbortController();

    this.loading = true;
    this._showLoading(append);

    try {
      const url = new URL(this.options.endpoint, window.location.origin);
      url.searchParams.set('q', query);
      url.searchParams.set('page', this.currentPage);
      url.searchParams.set('per_page', this.options.perPage);

      Object.entries(this.additionalParams).forEach(([key, val]) => {
        if (val !== null && val !== undefined && val !== '') url.searchParams.set(key, val);
      });

      const response = await fetch(url, {
        signal: this._abortController.signal,
        headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
      });

      if (!response.ok) throw new Error(`HTTP ${response.status}`);

      const data   = await response.json();
      this.results = append ? [...this.results, ...data.results] : data.results;
      this.hasMore = data.has_more || false;
      this._renderResults(append);
    } catch (err) {
      if (err.name === 'AbortError') return; // request was intentionally cancelled
      console.error('RemoteSelect fetch error:', err);
      this._showError();
    } finally {
      this.loading = false;
    }
  }

  _showLoading(append) {
    if (!append) {
      this._setMessage(this.options.loadingText, 'remote-select-loader');
    } else {
      const loader = document.createElement('div');
      loader.className = 'remote-select-message remote-select-loader';
      loader.textContent = this.options.loadingText;
      this.resultsContainer.appendChild(loader);
    }
  }

  _showError() {
    this._setMessage('Error loading results', 'remote-select-error');
  }

  // Clear the results area and render a single status message (safe — uses textContent)
  _setMessage(text, extraClass = '') {
    this.resultsContainer.innerHTML = '';
    const msg = document.createElement('div');
    msg.className = ['remote-select-message', extraClass].filter(Boolean).join(' ');
    msg.textContent = text;
    this.resultsContainer.appendChild(msg);
  }

  _renderResults(append) {
    if (!append) {
      this.resultsContainer.innerHTML = '';
      this.focusedIndex = -1;
    } else {
      const loader = this.resultsContainer.querySelector('.remote-select-loader');
      if (loader) loader.remove();
    }

    if (this.results.length === 0 && !append) {
      this._setMessage(this.options.emptyText);
      return;
    }

    const toRender = append ? this.results.slice(-this.options.perPage) : this.results;

    toRender.forEach(result => {
      const escapedId = CSS.escape(String(result.id));
      if (append && this.resultsContainer.querySelector(`[data-value="${escapedId}"]`)) return;

      const item = document.createElement('div');
      item.className    = 'remote-select-item';
      item.id           = `${this._uid}-option-${result.id}`;
      item.dataset.value = result.id;
      item.textContent  = result.text; // textContent — never innerHTML — prevents XSS
      item.setAttribute('role', 'option');
      item.setAttribute('aria-selected', 'false');

      item.addEventListener('click', (e) => {
        e.stopPropagation();
        this.selectItem(result.id, result.text);
      });

      this.resultsContainer.appendChild(item);
    });
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  selectItem(value, text) {
    this.selectedValue = value;
    this.selectedText  = text;
    this.element.value = value;
    this.element.dispatchEvent(new Event('change', { bubbles: true }));
    this._updateTriggerDisplay();
    this.closeDropdown();
    this.trigger.focus();
  }

  clearSelection() {
    this.selectedValue = '';
    this.selectedText  = '';
    this.element.value = '';
    this._updateTriggerDisplay();
    this.element.dispatchEvent(new Event('change', { bubbles: true }));
  }

  toggleDropdown() {
    this.container.classList.contains('is-open') ? this.closeDropdown() : this.openDropdown();
  }

  openDropdown() {
    if (this.container.classList.contains('is-open')) return;
    this.container.classList.add('is-open');
    this.trigger.setAttribute('aria-expanded', 'true');
    this.searchInput.value = '';
    this.currentQuery = '';
    this.currentPage  = 1;
    this.focusedIndex = -1;
    this._setMessage(this.options.placeholder);
    this.searchInput.focus();
  }

  closeDropdown() {
    if (!this.container.classList.contains('is-open')) return;
    this.container.classList.remove('is-open');
    this.trigger.setAttribute('aria-expanded', 'false');
    this.trigger.removeAttribute('aria-activedescendant');
    this.searchInput.removeAttribute('aria-activedescendant');
    this.searchInput.value = '';
    this.focusedIndex = -1;
  }

  setParam(key, value) { this.additionalParams[key] = value; }
  clearParams() { this.additionalParams = {}; }

  destroy() {
    if (this._abortController) this._abortController.abort();
    document.removeEventListener('click', this._outsideClickHandler);
    this._dependencyHandlers.forEach(({ element, handler }) => {
      element.removeEventListener('change', handler);
    });
    this._dependencyHandlers = [];
    this.container.remove();
    this.element.style.display = '';
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  _updateTriggerDisplay() {
    this.valueSpan.textContent = this.selectedText || this.options.placeholder;
    this.trigger.classList.toggle('has-value', Boolean(this.selectedValue));
  }

  _isScrolledToBottom() {
    const { scrollHeight, scrollTop, clientHeight } = this.resultsContainer;
    return scrollHeight - scrollTop - clientHeight < 50;
  }
}

// ─── Module-level helpers ─────────────────────────────────────────────────────

function _parseBool(value, defaultValue) {
  if (value === undefined || value === null) return defaultValue;
  if (typeof value === 'boolean') return value;
  return value !== 'false' && value !== '0';
}

// ─── Auto-init (Turbo-compatible, no Stimulus required) ──────────────────────

const _rsInstances = new WeakMap();

function _rsInit(root = document) {
  root.querySelectorAll('[data-remote-select]').forEach(el => {
    if (!_rsInstances.has(el)) _rsInstances.set(el, new RemoteSelect(el));
  });
}

function _rsDestroy(root = document) {
  root.querySelectorAll('[data-remote-select]').forEach(el => {
    if (_rsInstances.has(el)) {
      _rsInstances.get(el).destroy();
      _rsInstances.delete(el);
    }
  });
}

// Works without Turbo — fires on plain page load
document.addEventListener('DOMContentLoaded', () => _rsInit());

// Turbo full-page navigation (no-op if Turbo is not present)
document.addEventListener('turbo:load', () => _rsInit());

// Turbo Frames — scope init to just the updated frame element
document.addEventListener('turbo:frame-load', (e) => _rsInit(e.target));

// Cleanup before Turbo replaces the DOM — removes event listeners before elements are gone
document.addEventListener('turbo:before-render',       (e) => _rsDestroy(e.detail.newBody));
document.addEventListener('turbo:before-frame-render', (e) => _rsDestroy(e.target));

// Global export for <script> tag / CDN usage
window.RemoteSelect = RemoteSelect;

// ESM export for importmaps (Rails 8 default) and bundlers (esbuild, rollup, etc.)
export { RemoteSelect };
export default RemoteSelect;
