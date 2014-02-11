module DTK
  class ConfigAgent
    class ParseErrors < ErrorUsage
      attr_reader :error_list
      def initialize(config_agent_type)
        @config_agent_type = config_agent_type
        @error_list = Array.new
      end
      def add(error_info)
        if error_info.kind_of?(ParseError)
          @error_list << error_info
        elsif error_info.kind_of?(ParseErrors)
          @error_list += error_info.error_list
        end
        self
      end
      def to_s()
        preamble = 
          if @config_agent_type == :puppet
            "Puppet manifest parse error"
          else
            "Parse error"
          end
        preamble << ((@error_list.size > 1) ? "s:\n" : ":\n")

        "#{preamble}  #{@error_list.map{|e|e.to_s}.join('\n  ')}"
      end
    end
  end
end
