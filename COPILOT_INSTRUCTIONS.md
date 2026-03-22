# remote_select — AI Coding Assistant Integration Guide

> Concise reference for LLMs and coding assistants integrating `remote_select` into Rails applications.

## What it is

A **Ruby gem** (not an npm package) providing a searchable remote-data select for Rails forms. Zero JS dependencies, no jQuery, no Stimulus required. Works with Turbo.

## Quick integration checklist

1. `gem "remote_select"` in Gemfile → `bundle install`
2. `rails generate remote_select:install` (copies JS + CSS, prints pipeline-specific instructions)
3. Import JS in entry point (see pipeline table below)
4. Import CSS in entry point (see pipeline table below)
5. Add `remote_select()` helper in form view
6. Create JSON search endpoint in controller

## Asset pipeline setup

| Pipeline | JS import | CSS import |
|----------|-----------|------------|
| **esbuild / rollup / webpack** | `import "./remote_select"` in `application.js` | `@import "./remote_select";` in SCSS/CSS entry |
| **importmap (Rails 8)** | `pin "remote_select"` in `config/importmap.rb` + `import "remote_select"` | `*= require remote_select` in `application.css` |
| **Sprockets** | `//= require remote_select` | `*= require remote_select` |

For **esbuild/rollup/webpack**: the generator **must** be run — bare `import "remote_select"` will fail because the gem path is not in `node_modules`.

For **importmap/Sprockets**: the generator is optional — the engine registers asset paths automatically.

## View helper signature

```ruby
remote_select(form, attribute, endpoint, options = {})
```

### Parameters

- `form` — Rails form builder instance
- `attribute` — model attribute symbol (e.g., `:company_id`)
- `endpoint` — URL string returning JSON (e.g., `search_companies_path`)
- `options` — Hash:

| Key | Type | Default |
|-----|------|---------|
| `:selected_value` | String/Integer | `nil` |
| `:selected_text` | String | `nil` |
| `:min_chars` | Integer | `2` |
| `:debounce_delay` | Integer | `250` |
| `:placeholder` | String | `"Type to search..."` |
| `:per_page` | Integer | `20` |
| `:depends_on` | String | `nil` (CSS selectors, comma-separated) |
| `:clear_on_dependency_change` | Boolean | `true` |
| `:empty_text` | String | `"No results found"` |
| `:loading_text` | String | `"Loading..."` |
| `:html` | Hash | `{}` (extra attrs on hidden input) |

## Typical form usage

```erb
<%= form_with model: @article do |form| %>
  <%= remote_select(form, :company_id, search_companies_path,
        selected_value: @article.company_id,
        selected_text:  @article.company&.name,
        placeholder: "Search companies...",
        min_chars: 2) %>
<% end %>
```

## Dependent select pattern

```erb
<%= form.select :country_id, countries_options, {}, { id: "country-select" } %>
<%= remote_select(form, :city_id, search_cities_path,
      depends_on: "#country-select",
      clear_on_dependency_change: true) %>
```

The `country_id` param is automatically appended to the fetch URL when the parent changes.

## Required JSON endpoint

The controller action receives `q`, `page`, `per_page` as query params (plus any dependency params). It must return:

```ruby
def search_companies
  query    = params[:q].to_s.strip
  page     = (params[:page] || 1).to_i
  per_page = (params[:per_page] || 20).to_i

  scope = Company.order(:name)
  scope = scope.where("name ILIKE ?", "%#{query}%") if query.present?

  total   = scope.count
  results = scope.limit(per_page).offset((page - 1) * per_page)

  render json: {
    results:  results.map { |c| { id: c.id, text: c.name } },
    has_more: (page * per_page) < total
  }
end
```

### Accepted response shapes

```json
{ "results": [{ "id": 1, "text": "Name" }], "has_more": true }
```

```json
{ "results": [{ "id": 1, "text": "Name" }], "pagination": { "more": true } }
```

Both formats work. Each result object **must** have `id` and `text` keys.

## Route example

```ruby
# config/routes.rb
get "companies/search", to: "companies#search", as: :search_companies
```

## Theming

Override CSS custom properties — no need to edit the stylesheet:

```css
.remote-select-container {
  --rs-focus-border-color: #198754;
  --rs-border-radius: 0.25rem;
  --rs-dropdown-max-height: 400px;
}
```

## Common mistakes to avoid

1. **Do NOT** use bare `import "remote_select"` with esbuild/webpack — run the generator first
2. **Do NOT** add an npm package — this is a Ruby gem only
3. **Do NOT** forget the `text` key in JSON results — `name` won't work, must be `text`
4. **Do NOT** skip `selected_text` when setting `selected_value` — both are needed for preselection display
5. **Do NOT** add Stimulus controllers — the component auto-initializes on `DOMContentLoaded` and `turbo:load`
6. **Do NOT** manually `include RemoteSelect::ViewHelpers` in `ApplicationHelper` —
   the constant is not yet defined at that load stage and you'll get a `NameError`.
   The engine registers the helper automatically via `on_load(:action_view)`.
   If for any reason that doesn't fire, add an initializer instead:
 ```ruby
 # config/initializers/remote_select.rb
 Rails.application.config.to_prepare do
   ActionView::Base.include RemoteSelect::ViewHelpers
 end
 ```
## JS API (for programmatic use)

```js
const el = document.querySelector('[data-remote-select]');
// Access instance if needed:
const rs = new RemoteSelect(el, { endpoint: '/search', minChars: 1 });
rs.setParam('category', 'books');
rs.clearSelection();
rs.destroy();
```
