# TODO: bring in a production quality ruby logging capability that gets wrapped here
# TODO: would put this in config
module XYZ
  module Log
    Config = Hash.new
    Config[:print_time] = false
    Config[:print_method] = false
  end
end

module XYZ
  module Log
    def self.info(msg, out = $stdout)
      ::Ramaze::Log.info(msg)
    end
    def self.debug(msg, out = $stdout)
      ::Ramaze::Log.debug(msg)
    end
    def self.error(msg, out = $stdout)
      ::Ramaze::Log.error(msg)
    end
    def self.info_pp(obj, out = $stdout)
      out << "info: "
      out << Aux::pp_form(obj)
      obj
    end
    def self.debug_pp(obj, out = $stdout)
      out << "debug: "
      out << Aux::pp_form(obj)
      obj
    end
    def self.warn(msg, out = $stdout)
      ::Ramaze::Log.warn(msg)
    end
    def self.error_pp(obj, out = $stdout)
      out << "error: "
      out << Aux::pp_form(obj)
      obj
    end
   private
    def self.format(msg)
      ret = String.new
      ret << "#{Time.now}: " if Config[:print_time]
      ret << "in fn: #{this_parent_method}: " if Config[:print_method]
      if msg.kind_of?(String)
        ret << msg
      else
        ret << msg.inspect
      end
      ret << "\n"
    end
  end
end
