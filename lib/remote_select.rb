require "remote_select/version"
require "remote_select/view_helpers"

module RemoteSelect
  # Engine is only loaded in a Rails context
  require "remote_select/engine" if defined?(Rails)
end
