require 'optparse'
module DTK
  module Client
    class CommandBaseOptionParser
      include CommandBase
      def initialize(conn)
        @conn = conn
      end

      def self.execute_from_cli(conn,argv)
        return conn.connection_error if conn.connection_error
        method, args_hash = OptionParser.parse_options(self,argv)
        instance = new(conn)
        raise Error.new("Illegal subcommand #{method}") unless instance.respond_to?(method)
        instance.send(method,args_hash)
      end
      class << self
        include Aux
        def command_name()
          snake_form(self,"-")
        end
      end
    end
    class OptionParser
      def self.parse_options(command_class,argv)
        args_hash = Hash.new
        unless subcommand = argv[0]
          raise Error.new("No subcommand given")
        end
        method = subcommand.to_sym
        unless parse_info = (command_class.const_get "CLIParseOptions")[subcommand.to_sym]
          return [method,args_hash]
        end
        ::OptionParser.new do|opts|
          opts.banner = "Usage: #{command_class.command_name} #{subcommand} [options]"
          (parse_info[:options]||[]).each do |parse_info_option|
            raise Error.new("missing param name") unless param_name = parse_info_option[:name]
            raise Error.new("missing optparse spec") unless parse_info_option[:optparse_spec]
            opts.on(*parse_info_option[:optparse_spec]) do |val|
              args_hash[param_name.to_s] = val ? val : true
            end
          end

          opts.on('-h', '--help', 'Display this screen') do
            puts opts
            exit
          end
        end.parse!(argv)
        [method,args_hash]
      end
    end
  end
end
