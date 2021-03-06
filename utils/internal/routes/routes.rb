#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module DTK
  Routes = HashObject::AutoViv.create

  class ReactorRoute
    include Singleton

    def self.draw(&block)
      instance.mapper.instance_exec(&block)
    end

    def self.validate_route(rest_type, route)
     instance.mapper.validate_route(rest_type, route)
    end

    attr_reader :mapper

    private

    def initialize
      @mapper = Mapper.new
    end
  end

  class Mapper

    VALUE_PLACEHOLDER = '([\w\.:\[\]\-]+)'

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

    def delete(entry)
      if entry.keys.first.match(/\:\w+/)
        @regex_routes[:DELETE].merge!(transform_regex_value(entry))
      else
        @routes[:DELETE].merge!(transform_value(entry))
      end
    end


    def method_missing(name, *_args, &_block)
      fail "REST method '#{name}' is not supported via Reactor Routes."
    end

    def validate_route(rest_type, route)
      http_protocol = rest_type.upcase.to_sym
      # we first check simple string paths for speed
      found_route = @routes[http_protocol].fetch(route, nil)

      # we check now regex routes
      unless found_route
        @regex_routes[http_protocol].each do |route_regex, route_values|
          if matched = route.match(route_regex)
            # we need to make sure this is a full match
            if matched[0].eql?(route)
              # lets build value hash
              value_params = Hash[route_values[:params].zip(matched.captures)]
              return [route_values[:path], value_params]
            end
          end
        end
        # CODE GOES HERE
      end

      return [nil, nil] unless found_route

      return [found_route[:path], nil]
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
          params_values << ev.gsub(':', '')
          ev.eql?(':task_action') ? '(.*)' : VALUE_PLACEHOLDER
        else
          ev
        end
      end

      # regex that will be used for matching
      key_regex = Regexp.new(entry_values.join('/'))
      { key_regex => { path: entry.values.first.split('#'), params: params_values }}
    end
  end
end
