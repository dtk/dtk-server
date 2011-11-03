module XYZ
  class ActionsetController < Controller
    def process(*route)
      unless route.first == "user"
        login_first unless defined?(R8::EnvironmentConfig::TestUser)  #TODO unless clause for testing
        session = CurrentSession.new
        session.set_user_object(user_object())
        session.set_auth_filters(:c,:group_ids)
      end
      @json_response = true if ajax_request?

      #seperate route in 'route_key' (e.g., object/action, object) and its params 'action_set_params'
      #first two (or single items make up route_key; the rest are params
      route_key = route[0..1].join("/")
      action_set_params = route[2..route.size-1]||[]
      model_name = route[0].to_sym 

      action_set_def = R8::Routes[route_key] || Hash.new
      @action_set_param_map = ret_action_set_param_map(action_set_def,action_set_params)

      @layout = (R8::Routes[route_key] ? R8::Routes[route_key][:layout] : nil) || R8::Config[:default_layout]

      #if a config is defined for route, use values from config
      if action_set_def[:action_set]
        run_action_set(action_set_def[:action_set],model_name)
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
    #parent_model_name only set when top leevl action decomposed as opposed to when an action set of length one is created
    def run_action_set(action_set,parent_model_name=nil)
      #Execute each of the actions in the action_set and set the returned content
      (action_set || []).each do |action|
        ctrl_result = Hash.new
        result = call_action(action,parent_model_name)

        if !result.nil? && result.length > 0
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
        end

        ctrl_result[:js_includes] = ret_js_includes()
        ctrl_result[:css_includes] = ret_css_includes()
        ctrl_result[:js_exe_list] = ret_js_exe_list()

        model,method = action[:route].split("/")
        method ||= :index
        action_namespace = "#{R8::Config[:application_name]}_#{model}_#{method}".to_sym
=begin
#DEBUG
pp ctrl_result
pp ')))))))))))))))))))))))))))))))))))))))))))))'
=end
        @ctrl_results[action_namespace] = ctrl_result
        @ctrl_results[:as_run_list] << action_namespace
      end
    end

    def call_action(action,parent_model_name=nil)
      model,method = action[:route].split("/")
      method ||= :index
      model_name = model.to_sym
      processed_params = process_action_params(action[:action_params]) 
      action_set_params = ret_search_object(processed_params,model_name,parent_model_name)
      uri_params = ret_uri_params(processed_params)
#DEBUG
#p '++++++++++++++++++++++++'
#pp uri_params
#p '++++++++++++++++++++++++'

      a = Ramaze::Action.create(
        :node => XYZ.const_get("#{model.capitalize}Controller"),
        :method => method.to_sym,
        :params => uri_params,
        :engine => lambda{|action, value| value },
        :variables => {
          :js_includes => @js_includes,
          :css_includes => @css_includes,
          :js_exe_list => @js_exe_list,
          :action_set_params => action_set_params
        }
       )
      return a.call
    end


    def ret_search_object(processed_params,model_name,parent_model_name=nil)
      #TODO: assume everything is just equal
      filter_params = processed_params.select{|p|p.kind_of?(Hash)}
      return nil if filter_params.empty?
      #for processing :parent_id
      parent_id_field_name = ModelHandle.new(ret_session_context_id(),model_name,parent_model_name).parent_id_field_name()
      filter = [:and] + filter_params.map do |el|
        raw_pair = [el.keys.first,el.values.first]
        [:eq] +  raw_pair.map{|x| x == :parent_id ?  parent_id_field_name : x}
      end
      {"search" => {
          "search_pattern" => {
            :relation => model_name,
            :filter => filter
          }
        } 
      }
    end

    def ret_uri_params(processed_params)
      processed_params.select{|p|not p.kind_of?(Hash)}
    end

    #does substitution of free variables in raw_params
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


#TODO: lets finally kill off the xyz and move route loading into some sort of initialize or route setup call
  #enter the routes defined in config into Ramaze

    Ramaze::Route["route_to_actionset"] = lambda{ |path, request|
      if path =~ Regexp.new("^/xyz") and not path =~ Regexp.new("^/xyz/devtest") 
        path.gsub(Regexp.new("^/xyz"),"/xyz/actionset/process")
      end
    }
  end
end
