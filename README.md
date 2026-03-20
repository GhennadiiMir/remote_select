# remote_select

A lightweight, zero-dependency Rails form helper that renders a searchable select whose options are fetched from a JSON endpoint.

Replaces Select2 / Tom Select for the common case of "type to search a remote list" — with no npm packages, no jQuery, and full Turbo support.

## Features

- **Remote data fetching** with debouncing and request cancellation (AbortController)
- **Keyboard navigation** — ↑↓ arrows, Enter to select, Escape to close
- **Full ARIA** — `role="combobox"`, `aria-expanded`, `aria-activedescendant`, `role="listbox"`
- **Pagination** — infinite scroll loading of additional results
- **Dependent selects** — pass values from other fields as query parameters automatically
- **Auto-clearing** — clear selection when a dependency changes
- **Minimum character threshold** — configurable before search fires
- **Preselected values** — display preselected options on page load
- **i18n** — default strings resolved via `I18n.t` with English fallbacks
- **Turbo compatible** — full-page navigation and Turbo Frames, no Stimulus required
- **No dependencies** — pure vanilla JavaScript

## Installation

Add to your `Gemfile`:

```ruby
gem "remote_select"
```

Run:

```bash
bundle install
```

### JavaScript

**Importmap** (Rails 8 default):

```ruby
# config/importmap.rb
pin "remote_select", to: "remote_select.js"
```

```js
// app/javascript/application.js
import "remote_select"
```

**esbuild / rollup / webpack**:

```js
import "remote_select"
```

**Sprockets** (`application.js`):

```js
//= require remote_select
```

### Stylesheet

**Sass / SCSS**:

```scss
@import 'remote_select';
```

**Sprockets** (`application.css`):

```css
/*= require remote_select */
```

## Usage

### Basic

```erb
<%= form_with model: @article do |form| %>
  <%= form.label :company_id %>
  <%= remote_select(form, :company_id, search_companies_path,
        placeholder: "Type to search companies...",
        min_chars: 2) %>
<% end %>
```

### With preselected value

```erb
<%= remote_select(form, :company_id, search_companies_path,
      selected_value: @article.company_id,
      selected_text:  @article.company&.name) %>
```

### Dependent select (clears when parent changes)

```erb
<%# Parent — standard Rails select %>
<%= form.select :source, sources_options, {}, { id: "source-selector" } %>

<%# Child — clears and re-fetches when source changes %>
<%= remote_select(form, :company_id, search_companies_path,
      depends_on: "#source-selector",
      clear_on_dependency_change: true) %>
```

### Multiple dependencies

```erb
<%= remote_select(form, :city_id, search_cities_path,
      depends_on: "#state-selector, #country-selector") %>
```

## Helper options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `endpoint` | String | required | JSON endpoint URL |
| `selected_value` | String/Integer | `nil` | Pre-selected value ID |
| `selected_text` | String | `nil` | Pre-selected display text |
| `min_chars` | Integer | `2` | Chars needed before search fires |
| `debounce_delay` | Integer | `250` | Debounce in milliseconds |
| `placeholder` | String | i18n | Placeholder text |
| `per_page` | Integer | `20` | Results per page |
| `depends_on` | String | `nil` | CSS selector(s) of dependency field(s) |
| `clear_on_dependency_change` | Boolean | `true` | Clear when dependency changes |
| `empty_text` | String | i18n | Text shown when no results |
| `loading_text` | String | i18n | Text shown while loading |
| `html` | Hash | `{}` | Extra HTML attrs on the hidden input |

## i18n

Override any key in your locale files:

```yaml
# config/locales/en.yml
en:
  remote_select:
    placeholder: "Type to search..."
    empty_text: "No results found"
    loading_text: "Loading..."
```

## Backend endpoint

Your action must return JSON:

```ruby
def search_companies
  query    = params[:q].to_s.strip
  page     = (params[:page] || 1).to_i
  per_page = (params[:per_page] || 20).to_i

  companies = Company.order(:name)
  companies = companies.where("name ILIKE ?", "%#{query}%") if query.present?

  total   = companies.count
  results = companies.limit(per_page).offset((page - 1) * per_page)

  render json: {
    results:  results.map { |c| { id: c.id, text: c.name } },
    has_more: (page * per_page) < total,
    total:    total
  }
end
```

### Required response shape

```json
{
  "results":  [{ "id": 1, "text": "Acme Corp" }],
  "has_more": true,
  "total":    150
}
```

## Theming

All visual properties are CSS custom properties on `.remote-select-container`. Override without touching the stylesheet:

```css
.my-form .remote-select-container {
  --rs-focus-border-color: #198754;
  --rs-focus-shadow: 0 0 0 0.25rem rgba(25, 135, 84, 0.25);
  --rs-item-hover-bg: #d1e7dd;
  --rs-border-radius: 0.25rem;
  --rs-dropdown-max-height: 400px;
}
```

## JavaScript API

```js
// Manual init
const rs = new RemoteSelect(document.querySelector('#my-input'), {
  endpoint: '/api/search',
  minChars: 3
});

rs.setParam('category', 'books'); // add extra query param
rs.clearParams();                 // remove all extra params
rs.clearSelection();
rs.openDropdown();
rs.closeDropdown();
rs.destroy();                     // remove all listeners + DOM
```

## Browser support

Modern browsers (Chrome, Firefox, Safari, Edge). Requires ES2020 (`??`, `async/await`, `AbortController`). No IE11.

## License

MIT
