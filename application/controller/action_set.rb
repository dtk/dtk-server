module XYZ
  class ActionsetController < Controller
    def process(*route)

      @json_response = true if ajax_request?

      #seperate route in 'route_key' (e.g., object/action, object) and its params 'action_set_params'
      #first two (or single items make up route_key; the rest are params
      route_key = route[0..1].join("/")
      action_set_params = route[2..route.size-1]||[]

      action_set_def = R8::Routes[route_key] || Hash.new
      @action_set_param_map = ret_action_set_param_map(action_set_def,action_set_params)

      @layout = (R8::Routes[route_key] ? R8::Routes[route_key][:layout] : nil) || R8::Config[:default_layout]

      #if a config is defined for route, use values from config
      if action_set_def[:action_set]
        run_action_set(action_set_def[:action_set])
      else #create an action set of length one and run it
        action_params = action_set_params 
        query_string = ret_parsed_query_string_from_uri()
        action_params << query_string unless query_string.empty?
        action_set = 
          [{
              :route => action_set_def[:route] || route_key,
              :panel => action_set_def[:panel] || :main_body,
              :assign_type => action_set_def[:assign_type] || :replace,
              :action_params => action_params,
           }]
        run_action_set(action_set)
      end
    end
   private
    def run_action_set(action_set)
      #Execute each of the actions in the action_set and set the returned content
      (action_set || []).each do |action|
        ctrl_result = Hash.new
        result = call_action(action)

        #if a hash is returned, turn make result an array list of one
        (result.class == Hash) ? ctrl_result[:content] = [result] : ctrl_result = result

        panel_content_track = {}
        #for each piece of content set by controller result,make sure panel and assign type is set
        ctrl_result[:content].each_with_index do |item,index|
          #set the appropriate panel to render results to
          panel_name = (ctrl_result[:content][index][:panel] || action[:panel] || :main_body).to_sym
          panel_content_track[panel_name] ? panel_content_track[panel_name] +=1 : panel_content_track[panel_name] = 1
          ctrl_result[:content][index][:panel] = panel_name

          (panel_content_track[panel_name] == 1) ? dflt_assign_type = :replace : dflt_assign_type = :append
          #set the appropriate render assignment type (append | prepend | replace)
          ctrl_result[:content][index][:assign_type] = (ctrl_result[:content][index][:assign_type] || action[:assign_type] || dflt_assign_type).to_sym

          #set js with base cache uri path
          ctrl_result[:content][index][:src] = "#{R8::Config[:base_js_cache_uri]}/#{ctrl_result[:content][index][:src]}" if !ctrl_result[:content][index][:src].nil?
        end

        ctrl_result[:js_includes] = ret_js_includes()
        ctrl_result[:css_includes] = ret_css_includes()
        ctrl_result[:js_exe_list] = ret_js_exe_list()

        model,method = action[:route].split("/")
        method ||= :index
        action_namespace = "#{R8::Config[:application_name]}_#{model}_#{method}".to_sym

        @ctrl_results[action_namespace] = ctrl_result
        @ctrl_results[:as_run_list] << action_namespace
      end
    end

    def call_action(action)
      params = process_action_params(action[:action_params])
      model,method = action[:route].split("/")
      method ||= :index
      a = Ramaze::Action.create(
        :node => XYZ.const_get("#{model.capitalize}Controller"),
        :method => method.to_sym,
        :params => params,
        :engine => lambda{|action, value| value },
        :variables => {
          :js_includes => @js_includes,
          :css_includes => @css_includes,
          :js_exe_list => @js_exe_list
        }
       )
      return a.call
    end

    def ret_action_set_param_map(action_set_def,action_set_params)
      ret = Hash.new
      return ret if action_set_def.nil?
      i = 0
      (action_set_def[:params]||[]).each do |param_name|
        if i < action_set_params.size
          ret[param_name] = action_set_params[i]
        else
          ret[param_name] = nil
          Log.info("action set param #{param_name} not specfied in action set call")
        end
        i = i+1
      end
      ret
    end

    def process_action_params(raw_params)
      #short circuit if no params that need substituting
      return raw_params if @action_set_param_map.empty?
      if raw_params.kind_of?(Array)
        raw_params.map{|p|process_action_params(p)}
      elsif raw_params.kind_of?(Hash)
        ret = Hash.new
        raw_params.each{|k,v|ret[k] = process_action_params(v)}
        ret
      elsif raw_params.kind_of?(String)
        ret = raw_params.dup
        @action_set_param_map.each{|k,v|ret.gsub!(Regexp.new("\\$#{k}\\$"),v.to_s)}
        ret
      else
        raw_params
      end
    end

#TODO: lets finally kill off the xyz and move route loading into some sort of initialize or route setup call
  #enter the routes defined in config into Ramaze

    Ramaze::Route["route_to_actionset"] = lambda{ |path, request|
      if path =~ Regexp.new("^/xyz")
        path.gsub(Regexp.new("^/xyz"),"/xyz/actionset/process")
      end
    }
  end
end
