module XYZ
  module ActionSet
    Delim = '__'
  end

  class ActionsetController < MainController
    def process(*route)
      #retrieve action_set_key and params
      action_set_key = String.new
      param_vals = route.dup
      until param_vals.first == ActionSet::Delim
        action_set_key << param_vals.shift << "/" 
      end
      action_set_key.chop!
      param_vals.shift
      action_set_def = R8::Routes[:action_set][action_set_key]
      raise Error.new("cannot find action set for route #{action_set_key}") unless action_set_def
      pp [:action_set_def,action_set_def]
      pp [:param_vals,param_vals]
      ret = {:tpl_contents => nil}
      action_processor = ActionProcessor.new(param_vals,action_set_def)
      (action_set_def[:action_set]||[]).each{|action|action_processor.process!(ret,action)}
      ret
    end
   private
    class ActionProcessor
      def initialize(param_vals,action_set_def)
        @param_assigns = Hash.new
        i = 0
        (action_set_def[:params]||[]).each do |param_name|
          @param_assigns[param_name] = param_vals[i]
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
            :engine => lambda{|action, value| value[:tpl_contents] })
        action_result = a.call
        if ret[:tpl_contents].nil?
          ret[:tpl_contents] = action_result
        else
        #TODO stub that just synactically appends
          ret[:tpl_contents] << action_result
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

  #enter the routes defined in config into Ramaze
  (R8::Routes[:action_set]||[]).each_key do |route|
    Ramaze::Route["/xyz/#{route}"] = lambda{ |path, request|
      if path =~ Regexp.new("^/xyz/#{route}")
        path.gsub(Regexp.new("^/xyz/#{route}"),"/xyz/actionset/process/#{route}/#{ActionSet::Delim}")
      end
    }
  end
end
