#TODO: move all this into main controller
#should aim to have only main and rest should all be controller mapped to models/routes

#TODO: right now all results are passed back up and set in @content in the views/xyz/actionset/default.erubis

module XYZ
  module ActionSet
    Delim = '__'
  end

  class ActionsetController < MainController

    def process(*route)
      @user_context = UserContext.new #TODO: stub
      route_key = String.new
      route_segments = route.dup
      until route_segments.first == ActionSet::Delim
        route_key << route_segments.shift << "/"
      end
      route_key.chop!
      route_segments.shift
      call_params = route_segments.dup

      #if a config is defined for route, use values from config
      if R8::Routes[route_key]
        @layout = R8::Routes[route_key][:layout] || R8::Config[:default_layout]

        if R8::Routes[route_key][:action_set]
#TODO: remove action set def once action processor is cleared out
          @action_set_def = R8::Routes[route_key]
          run_action_set(R8::Routes[route_key][:action_set],call_params)
        else
#TODO: create an action set of length one and run it
          route_cfg = R8::Routes[route_key]
          panel = route_cfg[:panel] || :main_body
          assign_type = route_cfg[:assign_type] || :append

          action_set = Array.new
          action_set << {
            :route => route_key,
#            :action_params => ["$id$"],
            :panel => panel,
            :assign_type => assign_type,
          }
          run_action_set(action_set,call_params)

          raise Error.new("No route config defined for #{route_key}")
        end
      else
#TODO: create an action set of length one and run it
      #else no config set, go with defaults
           action_set = Array.new
           action_set << {
             :route => route_key,
#             :action_params => ["$id$"],
             :panel => "main_body",
             :assign_type => :append,
           }
          run_action_set(action_set,call_params)
      end

    end

#TODO: this function should probably just take an action set to run
#call_params should probably be processed in controller and set to be accessible by others during the call
    def run_action_set(action_set,call_params)
#TODO: get rid of action processor and just integrate into controller
      action_processor = ActionProcessor.new(call_params,@action_set_def)

      #Execute each of the actions in the action_set and set the returned content
      (action_set || []).each do |action|
        ctrl_result = call_action(action,action_processor)

        #set the appropriate panel to render results to
        ctrl_result[:panel] = (ctrl_result[:panel] || action[:panel] || :main_body).to_sym

        #set the appropriate render assignment type (append | prepend | replace)
        ctrl_result[:assign_type] = (ctrl_result[:assign_type] || action[:assign_type] || :append).to_sym

        @ctrl_results << ctrl_result
      end
    end

    def call_action(action,action_proc)
      params = action_proc.process_action_params(action[:action_params])
      model,method = action[:route].split("/")
      a = Ramaze::Action.create(
          :node => XYZ.const_get("#{model.capitalize}Controller"),
          :method => method.to_sym,
          :params => params,
          :engine => lambda{|action, value| value })
      return a.call
    end


#TODO: move the param stuff into main controller

   private
    class ActionProcessor
      def initialize(call_params,action_set_def)
        @param_assigns = Hash.new
        i = 0
        (action_set_def[:params]||[]).each do |param_name|
          @param_assigns[param_name] = call_params[i]
          i = i+1
        end
      end

      def process!(ret,action)
        params = process_action_params(action[:action_params])
        node_name,method = action[:route].split("/")
        a = Ramaze::Action.create(
            :node => XYZ.const_get("#{node_name.capitalize}Controller"),
            :method => method.to_sym,
            :params => params,
            :engine => lambda{|action, value| value })
        action_result = a.call
        if ret.nil?
          ret = action_result
        else
        #TODO stub that just synactically appends
          ret << action_result
        end
      end

      def process_action_params(raw_params)
        #short circuit if no params that need substituting
        return raw_params if @param_assigns.empty?
        if raw_params.kind_of?(Array)
          raw_params.map{|p|process_action_params(p)}
        elsif raw_params.kind_of?(Hash)
          ret = Hash.new
          raw_params.each{|k,v|ret[k] = process_action_params(v)}
          ret
        elsif raw_params.kind_of?(String)
          ret = raw_params.dup
          @param_assigns.each{|k,v|ret.gsub!(Regexp.new("\\$#{k}\\$"),v.to_s)}
          ret
        else
          raw_params
        end
      end
    end
  end

#TODO: lets finally kill off the xyz and move route loading into some sort of initialize or route setup call
  #enter the routes defined in config into Ramaze
  (R8::Routes || []).each_key do |route|
    Ramaze::Route["/xyz/#{route}"] = lambda{ |path, request|
      if path =~ Regexp.new("^/xyz/#{route}")
        path.gsub(Regexp.new("^/xyz/#{route}"),"/xyz/actionset/process/#{route}/#{ActionSet::Delim}")
      end
    }
  end
end
