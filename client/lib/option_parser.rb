require 'optparse'
module R8
  module Client
    class OptionParser
      def self.parse_options(command_class)
        ret = Hash.new
        cmd_parse_class = command_class.const_get "Parse"
        ::OptionParser.new do|opts|
          opts.banner = cmd_parse_class.banner
          cmd_parse_class.options.each do |option_spec|
            opts.on(*option_spec[:command_line]) do
              #option_spec[:proc]
            end
          end
        end.parse!
      end
    end
  end
end
