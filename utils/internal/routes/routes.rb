
module R8
  Routes = XYZ::HashObject::AutoViv.create()

  class Mapper
    def initialize
      @routes = {}
    end

    def get(entry)
      @routes.merge!(transform_value('get', entry))
    end

    def post(entry)
      @routes.merge!(transform_value('post', entry))
    end

    def method_missing(name, *_args, &_block)
      raise "REST method '#{name}' is not supported via Reactor Routes."
    end

    def validate_route(rest_type, route)
      @routes.fetch("#{rest_type.downcase}_#{route}", nil)
    end

    private

    #
    # Returns Hash, key and value as controller name and action name
    def transform_value(type, entry)
      { "#{type}_#{entry.keys.first}" => entry.values.first.split('#') }
    end
  end

  class ReactorRoute
    include Singleton

    def self.draw(&block)
      ReactorRoute.instance.mapper.instance_exec(&block)
    end

    def self.validate_route(rest_type, route)
      ReactorRoute.instance.mapper.validate_route(rest_type, route)
    end

    def mapper
      @mapper
    end

    private

    def initialize
      @mapper = Mapper.new
    end
  end
end
