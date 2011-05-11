module XYZ
  class ParseLog
    def self.parse(lines)
      get_adapter().parse(lines)
    end
   private
    def self.get_adapter()
      adapter_type = :chef #TODO stub
      Adapters[adapter_type] ||= get_adapter_aux(adapter_type)
    end
    Adapters = Hash.new
    def self.get_adapter_aux(adapter_type)
      require File.expand_path("#{UTILS_DIR}/internal/parse_log/adapters/#{adapter_type}", File.dirname(__FILE__))
      XYZ::ParseLogAdapter.const_get adapter_type.to_s.capitalize
     rescue LoadError
      raise Error.new("cannot find log parser adapter")
    end
  end

  class LogSegments < Array
  end

  class LogSegment 
    attr_reader :type,:line,:aux_data
    def initialize(type,line)
      @type = type
      @line = line 
      @aux_data = Array.new
    end
    def <<(line)
      @aux_data << line
    end
  end
end
