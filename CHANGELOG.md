# Changelog

All notable changes to this project will be documented in this file.

## [0.2.0] - 2026-03-20

### Added
- **Install generator** (`rails generate remote_select:install`) — copies JS and CSS into the consuming app with pipeline-specific post-install instructions. Works with esbuild, rollup, webpack, importmap, and Sprockets.
- **Select2-compatible response parsing** — accepts both `has_more` and `pagination.more` response formats, enabling zero-backend-change migration from Select2.
- **AI assistant integration guide** (`COPILOT_INSTRUCTIONS.md`) — concise reference for coding assistants to integrate the gem correctly.
- **Minitest test suite** — view helper tests, generator tests, JS/CSS source integrity tests, version tests.
- **CSS custom properties documentation** in README with full theming reference table.
- **Version headers** in JS and CSS source files for traceability.

### Changed
- README restructured with generator-first installation flow, per-pipeline setup instructions (collapsible details), and dual response format documentation.

### Fixed
- JS/CSS files are now resolvable by esbuild, rollup, webpack, and Vite via the install generator (previously only worked with importmap/Sprockets).
- Pagination with `has_more: false` now correctly returns `false` (changed `||` to `??` to avoid truthy coercion).

## [0.1.0] - 2026-03-20

### Added
- Initial release
- `remote_select` form helper
- Vanilla JS widget (`RemoteSelect`) with remote data fetching
- Keyboard navigation and full ARIA support
- Pagination (infinite scroll)
- Dependent selects with auto-clearing
- Turbo (full-page + Frames) compatibility
- i18n support via Rails `I18n.t`
- CSS custom properties for zero-fork theming
