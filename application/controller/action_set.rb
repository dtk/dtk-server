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
require 'base64'

r8_require('../../utils/performance_service')

module DTK
  class ActionsetController < Controller
    def process(*route)
      route_key = route.join('/')
      action_set_params = []

      route, value_params = ReactorRoute.validate_route(request.request_method, route_key)

      # return 404 Resource Not Found if route is not valid
      respond("#{route_key}!", 404) unless route

      # set URL param values in request params
      request.params.merge!(value_params) if value_params

      # we set new model
      model_name = route.first.to_sym
      # we rewrite route key to new mapped one
      route_key = route.join('/')

      # we check cookie data
      begin
        ramaze_user = user_object()
      rescue ::Sequel::DatabaseDisconnectError, ::Sequel::DatabaseConnectionError => e
        respond(e, 403)
      end

      # we check simple http authentication now
      if ramaze_user.nil?
        # check requests for AUTHENTICATION HEADERS
        simple_auth_login = false
        simple_http_auth_creds = check_simple_http_authentication()
        simple_auth_login = login_without_response(simple_http_auth_creds) if simple_http_auth_creds
        ramaze_user = user_object() if simple_auth_login
      end

      unless route.first == 'user' || route.last == 'login'
        unless logged_in?
          unless R8::Config[:session][:cookie][:disabled]
            if request.cookies['dtk-user-info']
              # Log.debug "Session cookie is beeing used to revive this session"

              # using cookie to take session information
              # composed data is consistent form user_id, expire timestamp, and tenant id
              # URL encoding is transfering + sign to ' ', so we correct that via gsub
              cookie_data = Base64.decode64(request.cookies['dtk-user-info'].gsub(' ', '+'))
              composed_data = ::AESCrypt.decrypt(cookie_data, ENCRYPTION_SALT, ENCRYPTION_SALT)

              user_id, time_integer, c = composed_data.split('_')

              # make sure that cookie has not expired
              if (time_integer.to_i >= Time.now.to_i)
                # due to tight coupling between model_handle and user_object we will set
                # model handle manually
                begin
                  ramaze_user = User.get_user_by_id({ model_name: :user, c: c }, user_id)
                rescue ::Sequel::DatabaseDisconnectError, ::Sequel::DatabaseConnectionError => e
                  respond(e, 403)
                end

                # TODO: [Haris] This is workaround to make sure that user is logged in, due to Ramaze design
                # this is easiest way to do it. But does feel dirty.
                # TODO: [Haris] This does not work since user is not persisted, look into this after cookie bug is resolved
                user_login(ramaze_user.merge(access_time: Time.now))

                # we set :last_ts as access time for later check
                session.store(:last_ts, Time.now.to_i)

                # Log.debug "Session cookie has been used to temporary revive user session"
              end
            end
          end
        end

        session = CurrentSession.new
        session.set_user_object(ramaze_user)
        session.set_auth_filters(:c, :group_ids)

        login_first unless R8::Config[:development_test_user]
      end

      @json_response = true if ajax_request?

      # seperate route in 'route_key' (e.g., object/action, object) and its params 'action_set_params'
      # first two (or single items make up route_key; the rest are params

      action_set_def = Routes[route_key] || {}
      @action_set_param_map = ret_action_set_param_map(action_set_def, action_set_params)

      @layout = (Routes[route_key] ? Routes[route_key][:layout] : nil) || R8::Config[:default_layout]

      # if a config is defined for route, use values from config
      if action_set_def[:action_set]
        run_action_set(action_set_def[:action_set], model_name)
      else #create an action set of length one and run it
        action_set = compute_singleton_action_set(action_set_def, route_key, action_set_params)
        run_action_set(action_set)
      end
    end

    private

    def compute_singleton_action_set(action_set_def, route_key, action_set_params)
      action_params = action_set_params
      query_string = ret_parsed_query_string_from_uri()
      action_params << query_string unless query_string.empty?
      action = {
        route: action_set_def[:route] || route_key,
        action_params: action_params
      }
      unless rest_request?
        action.merge!(
          panel: action_set_def[:panel] || :main_body,
          assign_type: action_set_def[:assign_type] || :replace
        )
      end
      [action]
    end

    # parent_model_name only set when top level action decomposed as opposed to when an action set of length one is created
    def run_action_set(action_set, parent_model_name = nil)
      PerformanceService.log("OPERATION=#{action_set.first[:route]}")
      PerformanceService.log("REQUEST_PARAMS=#{request.params.to_json}")
      if rest_request?
        unless (action_set || []).size == 1
          fail Error.new('If rest response action set must just have one element')
        end
        PerformanceService.start('PERF_OPERATION_DUR')
        run_rest_action(action_set.first, parent_model_name)
        PerformanceService.end('PERF_OPERATION_DUR')
        return
      end

      @ctrl_results = ControllerResultsWeb.new

      # Execute each of the actions in the action_set and set the returned content
      (action_set || []).each do |action|
        model, method = action[:route].split('/')
        method ||= :index
        action_namespace = "#{R8::Config[:application_name]}_#{model}_#{method}".to_sym
        result = call_action(action, parent_model_name)

        ctrl_result = {}

        if result && result.length > 0
          # if a hash is returned, turn make result an array list of one
          if result.is_a?(Hash)
            ctrl_result[:content] = [result]
          else
            ctrl_result = result
          end
          panel_content_track = {}
          # for each piece of content set by controller result,make sure panel and assign type is set
          ctrl_result[:content].each_with_index do |_item, index|
            # set the appropriate panel to render results to
            panel_name = (ctrl_result[:content][index][:panel] || action[:panel] || :main_body).to_sym
            panel_content_track[panel_name] ? panel_content_track[panel_name] += 1 : panel_content_track[panel_name] = 1
            ctrl_result[:content][index][:panel] = panel_name

            (panel_content_track[panel_name] == 1) ? dflt_assign_type = :replace : dflt_assign_type = :append
            # set the appropriate render assignment type (append | prepend | replace)
            ctrl_result[:content][index][:assign_type] = (ctrl_result[:content][index][:assign_type] || action[:assign_type] || dflt_assign_type).to_sym

            # set js with base cache uri path
            ctrl_result[:content][index][:src] = "#{R8::Config[:base_js_cache_uri]}/#{ctrl_result[:content][index][:src]}" unless ctrl_result[:content][index][:src].nil?
          end
        end

        ctrl_result[:js_includes] = ret_js_includes()
        ctrl_result[:css_includes] = ret_css_includes()
        ctrl_result[:js_exe_list] = ret_js_exe_list()

        @ctrl_results.add(action_namespace, ctrl_result)
      end
    end

    def run_rest_action(action, parent_model_name = nil)
      model, method = action[:route].split('/')
      method ||= :index
      result = nil
      begin
       result = call_action(action, parent_model_name)
      rescue SessionTimeout => e
        # TODO: see why dont have result = auth_forbidden_response(e.message)
        Log.info "Session error: #{e.message}"
        auth_forbidden_response(e.message)
      rescue SessionError => e
        # TODO: see why dont have result = auth_unauthorized_response(e.message)
        auth_unauthorized_response(e.message)
      rescue ErrorUsage::Warning => warning
        result = rest_ok_response(warn: warning.message)
      rescue Exception => e
        if e.is_a?(ErrorUsage)
          # TODO: respond_to? is probably not needed
          unless e.respond_to?(:donot_log_error) && e.donot_log_error()
            Log.error_pp([e, e.backtrace[0]])
          end
        else
          Log.error_pp([e, e.backtrace[0..20]])
        end

        result = rest_notok_response(RestError.create(e).hash_form())
      end
      @ctrl_results = ControllerResultsRest.new(result)
    end

    def call_action(action, parent_model_name = nil)
      model, method = action[:route].split('/')

      controller_class = controller_clazz(model)
      method ||= :index
      if rest_request?()
        rest_variant = "rest__#{method}"
        if controller_class.method_defined?(rest_variant)
          method = rest_variant
        end
      end
      model_name = model.to_sym
      processed_params = process_action_params(action[:action_params])
      action_set_params = ret_search_object(processed_params, model_name, parent_model_name)
      uri_params = ret_uri_params(processed_params)
      variables = { action_set_params: action_set_params }
      unless rest_request?()
        variables.merge!(
          js_includes: @js_includes,
          css_includes: @css_includes,
          js_exe_list: @js_exe_list
        )
      end

      a = Ramaze::Action.create(
        node: controller_class,
        method: method.to_sym,
        params: uri_params,
        engine: lambda { |_action, value| value },
        variables: variables
      )

      a.call
    end

    def ret_search_object(processed_params, model_name, parent_model_name = nil)
      # TODO: assume everything is just equal
      filter_params = processed_params.select { |p| p.is_a?(Hash) }
      return nil if filter_params.empty?
      # for processing :parent_id
      parent_id_field_name = ModelHandle.new(ret_session_context_id(), model_name, parent_model_name).parent_id_field_name?()
      filter = [:and] + filter_params.map do |el|
        raw_pair = [el.keys.first, el.values.first]
        [:eq] + raw_pair.map { |x| x == :parent_id ? parent_id_field_name : x }
      end
      { 'search' => {
          'search_pattern' => {
            relation: model_name,
            filter: filter
          }
        }
      }
    end

    def ret_uri_params(processed_params)
      processed_params.select { |p| not p.is_a?(Hash) }
    end

    # does substitution of free variables in raw_params
    def process_action_params(raw_params)
      # short circuit if no params that need substituting
      return raw_params if @action_set_param_map.empty?
      if raw_params.is_a?(Array)
        raw_params.map { |p| process_action_params(p) }
      elsif raw_params.is_a?(Hash)
        ret = {}
        raw_params.each { |k, v| ret[k] = process_action_params(v) }
        ret
      elsif raw_params.is_a?(String)
        ret = raw_params.dup
        @action_set_param_map.each { |k, v| ret.gsub!(Regexp.new("\\$#{k}\\$"), v.to_s) }
        ret
      else
        raw_params
      end
    end

    def ret_action_set_param_map(action_set_def, action_set_params)
      ret = {}
      return ret if action_set_def.nil?
      i = 0
      (action_set_def[:params] || []).each do |param_name|
        if i < action_set_params.size
          ret[param_name] = action_set_params[i]
        else
          ret[param_name] = nil
          Log.info("action set param #{param_name} not specfied in action set call")
        end
        i += 1
      end
      ret
    end

    def controller_clazz(model_name)
      clazz = DTK

      if model_name.include?('::')
        namespace, model_name = model_name.split('::')
        clazz = clazz.const_get(namespace.capitalize)
      end

      clazz.const_get("#{model_name.capitalize}Controller")
    end

    # TODO: lets finally kill off the xyz and move route loading into some sort of initialize or route setup call
    # enter the routes defined in config into Ramaze

    Ramaze::Route['route_to_actionset'] = lambda do |path, _request|
      if path =~ Regexp.new('^/xyz') and not path =~ Regexp.new('^/xyz/devtest')
        path.gsub(Regexp.new('^/xyz'), '/xyz/actionset/process')
      elsif path =~ Regexp.new('^/rest')
        path.gsub(Regexp.new('^/rest'), '/xyz/actionset/process')
      end
    end
  end
end
