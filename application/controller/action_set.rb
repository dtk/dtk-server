#TODO: move all this into main controller
#should aim to have only main and rest should all be controller mapped to models/routes

#TODO: right now all results are passed back up and set in @content in the views/xyz/actionset/default.erubis

module XYZ
  module ActionSet
    Delim = '__'
  end

  class ActionsetController < MainController
    layout :bundle_and_return
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

      if R8::Routes[route_key] and R8::Routes[route_key][:action_set]
        @action_set_def = R8::Routes[route_key]
        run_action_set(call_params)
      else
        #TODO: shouldnt raise error if action not found, should just execute single controller as normal
        raise Error.new("No route config defined for #{route_key}")
      end
    end

    def run_action_set(call_params)
#TODO: get rid of action processor and just integrate into controller
      action_processor = ActionProcessor.new(call_params,@action_set_def)

      #Execute each of the actions in the action_set and set the returned content
      (@action_set_def[:action_set] || []).each do |action|
        ctrl_result = call_action(action,action_processor)

        #set the appropriate panel to render results to
        panel = (ctrl_result[:panel] || action[:panel] || :main_body).to_sym

        #set the appropriate render assignment type (append | prepend | replace)
        assign_type = (ctrl_result[:assign_type] || action[:assign_type] || :append).to_sym

        case assign_type
          when :append 
            (@regions_content[panel].nil?) ? 
            @regions_content[panel] = ctrl_result : 
              @regions_content[panel] << ctrl_result
          when :replace 
            @regions_content[panel] = ctrl_result
          when :prepend 
            if(@regions_content[panel].nil?) 
              @regions_content[panel] = ctrl_result
            else
              tmp_contents = @regions_content[panel]
              @regions_content[panel] = ctrl_result + tmp_contents
            end
          end  
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
