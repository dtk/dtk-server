module XYZ
  class ActionsetController < Controller
    def process(*route)
      set_user_context()
      
      #seperate route in 'route_key' (e.g., object/action, object) and its params 'action_set_params'
      route_key = String.new
      route_segments = route.dup
      until route_segments.first == ActionSet::Delim
        route_key << route_segments.shift << "/"
      end
      route_key.chop!
      route_segments.shift
      action_set_params = route_segments

      action_set_def = R8::Routes[route_key] || Hash.new
      @action_set_param_map = ret_action_set_param_map(action_set_def,action_set_params)

      @layout = (R8::Routes[route_key] ? R8::Routes[route_key][:layout] : nil) || R8::Config[:default_layout]

      #if a config is defined for route, use values from config
      if action_set_def[:action_set]
        run_action_set(action_set_def[:action_set])
      else #create an action set of length one and run it
        action_set = 
          [{
             :route => action_set_def[:route] || route_key,
             :panel => action_set_def[:panel] || :main_body,
             :assign_type => action_set_def[:assign_type] || :append,
             :action_params => action_set_params
           }]
        run_action_set(action_set)
      end
    end
   private
    module ActionSet
      Delim = '__'
    end
    def run_action_set(action_set)
      #Execute each of the actions in the action_set and set the returned content
      (action_set || []).each do |action|
        ctrl_result = Hash.new
        ctrl_result = call_action(action)

        #set the appropriate panel to render results to
        ctrl_result[:panel] = (ctrl_result[:panel] || action[:panel] || :main_body).to_sym

        #set the appropriate render assignment type (append | prepend | replace)
        ctrl_result[:assign_type] = (ctrl_result[:assign_type] || action[:assign_type] || :append).to_sym

        @ctrl_results << ctrl_result
      end
    end

    def call_action(action)
      params = process_action_params(action[:action_params])
      model,method = action[:route].split("/")
      method ||= :default
      a = Ramaze::Action.create(
          :node => XYZ.const_get("#{model.capitalize}Controller"),
          :method => method.to_sym,
          :params => params,
          :engine => lambda{|action, value| value })
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
  (R8::Routes || []).each_key do |route|
    Ramaze::Route["/xyz/#{route}"] = lambda{ |path, request|
      #TODO logic emploeyd uses keys in R8::Routes to split paramaters from mdethod/action
      # is there simple way which we can have simple routing role that just prepends process?
      if path =~ Regexp.new("^/xyz/#{route}")
        path.gsub(Regexp.new("^/xyz/#{route}"),"/xyz/actionset/process/#{route}/#{ActionSet::Delim}")
      end
    }
    end
  end
end
