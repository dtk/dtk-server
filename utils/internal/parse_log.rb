module XYZ
  class ParseLog

    def self.parse(adapter_type, lines)
      get_adapter(adapter_type).parse(lines)
    end
    def self.log_complete?(adapter_type, lines)
      get_adapter(adapter_type).log_complete?(lines)
    end

    private

    def self.get_adapter(adapter_type_x)
      adapter_type = adapter_type_x.to_sym
      Adapters[adapter_type] ||= get_adapter_aux(adapter_type)
    end
    Adapters = {}
    def self.get_adapter_aux(adapter_type)
      r8_nested_require('parse_log', "adapters/#{adapter_type}")
      XYZ::ParseLogAdapter.const_get adapter_type.to_s.capitalize
     rescue LoadError
      raise Error.new('cannot find log parser adapter')
    end
  end

  class LogSegments < Array
    def is_complete?
      @complete
    end

    def initialize
      super()
      @complete = nil
    end

    def hash_form
      {
        complete: @complete,
        log_segments: map(&:hash_form)
      }
    end
  end

  class LogSegment
    def self.create(type, line)
      LogSegmentGeneric.new(type, line)
    end
    def hash_form
      { type: type }
    end
    attr_reader :type

    private

    def initialize(type)
      @type = type
    end
  end

  class LogSegmentGeneric < LogSegment
    attr_reader :line, :aux_data
    def hash_form
      added = {
        line: @line,
        aux_data: @aux_data
      }
      super.merge(added)
    end

    def initialize(type, line)
      super(type)
      @line = line
      @aux_data = []
    end

    def <<(line)
      @aux_data << line
    end
  end

  class LogSegmentError < LogSegment
    attr_reader :error_type, :error_file_ref, :error_line_num, :error_lines, :error_detail
    def hash_form
      added = {
        error_type: @error_type,
        error_file_ref: @error_file_ref,
        error_line_num: @error_line_num,
        error_detail: @error_detail,
        error_lines: @error_lines
      }
      super.merge(added)
    end

    def initialize
      super(:error)
      @error_type = error_type
      @error_file_ref = nil
      @error_line_num = nil
      @error_detail = nil
      @error_lines = []
    end

    def ret_file_asset(model_handle)
      @error_file_ref && @error_file_ref.ret_file_asset(model_handle)
    end

    private

    def error_type
      Aux::underscore(Aux::demodulize(self.class.to_s)).to_sym
    end
  end
end
