
#TODO: move all this into main controller
#should aim to have only main and rest should all be controller mapped to models/routes

module XYZ
  module ActionSet
    Delim = '__'
  end

  class ActionsetController < MainController
    def process(*route)
      route_key = String.new
      route_segments = route.dup
      until route_segments.first == ActionSet::Delim
        route_key << route_segments.shift << "/"
      end
      route_key.chop!
      route_segments.shift
      call_params = route_segments.dup

      if(R8::Routes[route_key][:action_set]) then
        return self.run_action_set(R8::Routes[route_key],call_params)
      else
print "No route config defined for:"+route_key
      end

#      action_set_def = R8::Routes[route_key]

#TODO: shouldnt raise error if action not found, should just execute single controller as normal
#      raise Error.new("No route config defined for: #{route_key}") unless action_set_def

#TODO: move pp into some sort of dev class that will hold dev like tools
#pp [:action_set_def,action_set_def]
#pp [:call_params,call_params]
    end

    def call_action(action,action_processor)
      model_name,method = action[:route].split("/")
      params = action_processor.process_action_params(action[:action_params])
      a = Ramaze::Action.create(
          :node => XYZ.const_get("#{model.capitalize}Controller"),
          :method => method.to_sym,
          :params => params,
          :engine => lambda{|action, value| value[:tpl_contents] })

      return a.call
    end

    def run_action_set(action_set_def,call_params)
        ret = {:tpl_contents => nil}
        action_processor = ActionProcessor.new(call_params,action_set_def)

        ctrl_result = ''
        (action_set_def[:action_set] || []).each{ |action|
          ctrl_result << self.call_action(action,action_processor)
        }

  #### TODO: replace and enacapsulate elsewhere; hard wire calling of action set layout
        ### should we create a R8Template to handle production of layout template?
        layout = action_set_def[:layout] || R8::Config[:default_layout]
        layout_path = "#{R8::Config[:app_root_path]}/view/#{layout}.layout.rtpl"
        layout_tpl_contents = IO.read(layout_path) #TODO check file exists
        eruby =  Erubis::Eruby.new(layout_tpl_contents,:pattern=>'\{\% \%\}')
  
        #TODO had to create new class ActionSetInclude; where should it be populated from
        action_set_includes = ActionSetInclude.new
        #action_set_includes.css_includes = ..
  
  #TODO: hard wired in knowledge of panels; this should eb automatically driven by :panel in action sets
        template_vars = {
          "_app".to_sym => action_set_includes,
          :main_menu => "",
          :left_col => "",
          :main_body => ctrl_result
        }
        return eruby.result(template_vars)
    end

    class ActionSetInclude
      attr_accessor :css_includes, :js_includes, :base_uri
      def initialize()
        @css_includes = []
        @js_includes = []
        @base_uri = ""
      end
    end

#####TODO end of stubbed fn for action set layouts

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

      def process!(action)
        model_name,method = action[:route].split("/")
        params = process_action_params(action[:action_params])
        a = Ramaze::Action.create(
            :node => XYZ.const_get("#{model.capitalize}Controller"),
            :method => method.to_sym,
            :params => params,
            :engine => lambda{|action, value| value[:tpl_contents] })

        return a.call
=begin
        action_result = a.call
        if ret[:tpl_contents].nil?
          ret[:tpl_contents] = action_result
        else
        #TODO stub that just synactically appends
          ret[:tpl_contents] << action_result
        end
=end
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
