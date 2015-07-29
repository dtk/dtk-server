
module R8
  Routes = XYZ::HashObject::AutoViv.create()

  class Mapper

    VALUE_PLACEHOLDER = '\w+'

    def initialize
      @routes = {}
      @regex_routes = {}
      %w(get post put delete).each do |meth|
        @routes[meth.upcase.to_sym] = {}
        @regex_routes[meth.upcase.to_sym] = {}
      end
    end

    def get(entry)
      if entry.keys.first.match(/\:\w+/)
        @regex_routes[:GET].merge!(transform_regex_value(entry))
      else
        @routes[:GET].merge!(transform_value(entry))
      end
    end

    def post(entry)
      if entry.keys.first.match(/\:\w+/)
        @regex_routes[:POST].merge!(transform_regex_value(entry))
      else
        @routes[:POST].merge!(transform_value(entry))
      end
    end

    def method_missing(name, *_args, &_block)
      fail "REST method '#{name}' is not supported via Reactor Routes."
    end

    def validate_route(rest_type, route)
      # we first check simple string paths for speed
      found_route = @routes[rest_type.upcase.to_sym].fetch(route, nil)

      # we check now regex routes
      unless found_route
        # CODE GOES HERE
      end

      return nil unless found_route

      found_route[:path]
    end

    private

    #
    # Returns Hash, key and value as controller name and action name
    def transform_value(entry)
      { entry.keys.first => { path: entry.values.first.split('#') } }
    end

    def transform_regex_value(entry)
      entry_values  = entry.keys.first.split('/')
      params_values = []

      # we extract place holder to be matched later on
      entry_values = entry_values.collect do |ev|
        if ev.start_with?(':')
          params_values << ev.gsub(':', '').to_sym
          VALUE_PLACEHOLDER
        else
          ev
        end
      end

      # regex that will be used for matching
      key_regex = Regexp.new(entry_values.join('/'))
      { key_regex => { path: entry.values.first.split('#'), params: params_values }}
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

    attr_reader :mapper

    private

    def initialize
      @mapper = Mapper.new
    end
  end
end
