module RemoteSelect
  class Engine < ::Rails::Engine
    isolate_namespace RemoteSelect

    initializer "remote_select.helpers" do
      ActiveSupport.on_load(:action_view) do
        include RemoteSelect::ViewHelpers
      end
    end
  end
end
