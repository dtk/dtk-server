module XYZ
  class ConfigAgent
    def self.parse_given_module_directory(type,dir)
      load(type).parse_given_module_directory(dir)
    end
    def self.parse_given_filename(type,filename)
      load(type).parse_given_filename(filename)
    end
    def self.parse_given_file_content(type,file_path,file_content)
      load(type).parse_given_file_content(file_path,file_content)
    end

    #TODO: make private and wrap as ConfigAgent method like do for parse
    def self.load(type)
      return nil unless type
      return Agents[type] if Agents[type]
      klass = self
      begin
        Lock.synchronize do
          require File.expand_path("#{UTILS_DIR}/internal/config_agent/adapters/#{type}", File.dirname(__FILE__))
        end
        klass = XYZ::ConfigAgentAdapter.const_get type.to_s.capitalize
       rescue LoadError
        Log.error("cannot find config agent adapter; loading null config agent class")
      end
      Agents[type] = klass.new()
    end

    #common functions accross config agents

    def node_name(node)
      (node[:external_ref]||{})[:instance_id]
    end

    Lock = Mutex.new
    Agents = Hash.new

    class ParseError < Error
      attr_reader :msg, :filename, :line
      def initialize(msg,filename=nil,line=nil)
        @msg = msg
        @filename = filename
        @line = line
      end

      def to_s()
        [:msg, :filename, :line].map do |k|
          val = send(k)
          "#{k}=#{val}" if val
        end.compact.join("; ")
      end
    end
    class ParseErrors < Error
      attr_reader :error_list
      def initialize()
        @error_list = Array.new
      end
      def add(error)
        @error_list << error
        self
      end
    end
  end

  module ConfigAgentAdapter
  end
end
