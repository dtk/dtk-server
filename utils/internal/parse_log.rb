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
    def initialize()
      super()
      @complete = nil
    end
  end


  class LogSegment 
    def self.create(type,line)
      LogSegmentGeneric.new(type,line)
    end
    attr_reader :type
   private
    def initialize(type)
      @type = type
    end
  end

  class LogSegmentGeneric < LogSegment 
    attr_reader :line,:aux_data
    def initialize(type,line)
      super(type)
      @line = line 
      @aux_data = Array.new
    end
    def <<(line)
      @aux_data << line
    end
  end

  class LogSegmentError < LogSegment
    attr_reader :error_type,:error_file_ref,:error_line_num,:error_lines,:error_detail
    def initialize(error_type)
      super(:error)
      @error_type = error_type
      @error_file_ref = nil
      @error_line_num = nil
      @error_detail = nil
      @error_lines = Array.new
    end
  end
end
