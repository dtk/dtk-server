module XYZ
  class Log
    def self.info(msg, out = $stdout)
      out << (msg + "\n")
    end
    def self.info_pp(obj, out = $stdout)
      out << Aux::pp_form(obj)
    end
    def self.debug(msg, out = $stdout)
      out << (msg + "\n")
    end
    def self.debug_pp(obj, out = $stdout)
      out << Aux::pp_form(obj)
    end
  end
end
