require 'optparse'
module R8
  module Client
    class OptionParser
      def self.parse_options(command_class)
        ret = Hash.new
        parse_info = command_class.const_get "CLIParseOptions"
        ::OptionParser.new do|opts|
          opts.banner = parse_info[:banner] if parse_info[:banner]
          (parse_info[:options]||[]).each do |param_name,parse_info_option|
            raise Error.new("missing optparse spec") unless parse_info_option[:optparse_spec]
            opts.on(*parse_info_option[:optparse_spec]) do |val|
              ret[param_name] = val ? val : true
            end
          end
        end.parse!
        ret
      end
    end
  end
end
