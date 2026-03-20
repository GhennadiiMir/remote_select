require_relative "lib/remote_select/version"

Gem::Specification.new do |spec|
  spec.name        = "remote_select"
  spec.version     = RemoteSelect::VERSION
  spec.authors     = ["Ghennadii Mir"]
  spec.email       = [""]

  spec.summary     = "Lightweight vanilla-JS remote-data select for Rails forms"
  spec.description = <<~DESC
    A zero-dependency Rails form helper that renders a searchable dropdown
    whose options are fetched from a JSON endpoint. Supports pagination,
    dependent selects, keyboard navigation, full ARIA, i18n, and Turbo.
  DESC
  spec.homepage    = "https://github.com/GhennadiiMir/remote_select"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "app/**/*",
    "config/**/*",
    "LICENSE",
    "README.md",
    "CHANGELOG.md"
  ]

  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 7.0"
end
