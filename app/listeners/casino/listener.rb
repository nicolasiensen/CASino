module CASino
  class Listener
    # include helpers to have the route path methods (like sessions_path)
    include CASino::Engine.routes.url_helpers

    def initialize(controller)
      @controller = controller
    end

    def assign(name, value)
      @controller.instance_variable_set("@#{name}", value)
    end

    def assigned(name)
      @controller.instance_variable_get("@#{name}")
    end

    protected
    def cookies
      @controller.send(:cookies)
    end
  end
end
