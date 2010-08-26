#TODO: bring in a production quality ruby logging capability that gets wrapped here
module XYZ
  class Log
    def self.info(msg, out = $stdout)
      out << "in fn: #{this_parent_method}: msg\n"
    end
    def self.info_pp(obj, out = $stdout)
      out << Aux::pp_form(obj)
    end
    def self.debug(msg, out = $stdout)
      out << "in fn: #{this_parent_method}: msg\n"
    end
    def self.debug_pp(obj, out = $stdout)
      out << Aux::pp_form(obj)
    end
    def self.time_stamp(out = $stdout)
      out << "in fn: #{this_parent_method}: #{Time.now}\n"
    end
  end
end
