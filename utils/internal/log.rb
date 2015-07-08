# TODO: bring in a production quality ruby logging capability that gets wrapped here
# TODO: would put this in config
# TODO: out is no longer used adn should be removed after checking no calls use it
module DTK
  module Log
    Config[:print_time] = false
    Config[:print_method] = false
    Config[:include_caller] = [:error]
    Config[:include_caller_depth] = 5
  end
end

module DTK
  module Log
    def self.info(msg, _out = $stdout)
      simple_form(:info,msg)
    end
    def self.debug(msg, _out = $stdout)
      simple_form(:debug,msg)
    end
    def self.error(msg, _out = $stdout)
      simple_form(:error,msg)
    end
    def self.warn(msg, _out = $stdout)
      simple_form(:warn,msg)
    end

    def self.info_pp(obj, _out = $stdout)
      pp_form(:info,obj)
    end
    def self.debug_pp(obj, _out = $stdout)
      pp_form(:debug,obj)
    end
    def self.error_pp(obj, _out = $stdout)
      pp_form(:error,obj)
    end

    private

    def self.simple_form(type,msg)
      msg = include_caller_info?(type,msg)
      ramaze_log(type,msg)
    end

    def self.pp_form(type,obj)
      msg = Aux::pp_form(obj)
      msg = include_caller_info?(type,msg)
      ramaze_log(type,msg)
      obj
    end

    def self.ramaze_log(type,msg)
      ::Ramaze::Log.send(type,msg)
    end

    def self.include_caller_info?(type,msg)
      if (Config[:include_caller]||[]).include?(type)
        caller_depth = Config[:include_caller_depth] || 1
        msg += "\n#{Aux::pp_form(caller[OffsetDepth...OffsetDepth+caller_depth])}\n"
      end
      msg
    end
    OffsetDepth = 2 #so does not give caller info for errors itself

    def self.format(msg)
      ret = ''
      ret << "#{Time.now}: " if Config[:print_time]
      ret << "in fn: #{this_parent_method}: " if Config[:print_method]
      if msg.is_a?(String)
        ret << msg
      else
        ret << msg.inspect
      end
      ret << "\n"
    end
  end
end
