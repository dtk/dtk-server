require 'optparse'
module R8
  module Client
    class OptionParser
      def self.parse_options(command_class)
        args_hash = Hash.new
        unless subcommand = ARGV[0]
          raise Error.new("No subcommand given")
        end
        method = subcommand.to_sym
        unless parse_info = (command_class.const_get "CLIParseOptions")[subcommand.to_sym]
          return [method,args_hash]
        end
        ::OptionParser.new do|opts|
          opts.banner = parse_info[:banner] if parse_info[:banner]
          (parse_info[:options]||[]).each do |parse_info_option|
            raise Error.new("missing param name") unless param_name = parse_info_option[:name]
            raise Error.new("missing optparse spec") unless parse_info_option[:optparse_spec]
            opts.on(*parse_info_option[:optparse_spec]) do |val|
              args_hash[param_name.to_s] = val ? val : true
            end
          end
        end.parse!
        [method,args_hash]
      end
    end
  end
end
