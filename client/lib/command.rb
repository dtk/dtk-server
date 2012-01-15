module R8
  module Client
    def load_command(command_name)
      r8_nested_require("command",command_name)
    end
    class CommandBase
      def initialize(conn)
        @conn = conn
      end

      def execute_from_cli()
        method, args_hash = OptionParser.parse_options(self.class)
        raise Error.new("Illegal subcommand #{subcommand||""}") unless respond_to?(method)
        if @conn.connection_error
          return @conn.connection_error
        end
        send(method,args_hash)
      end

      def method_missing(method,*args)
        raise Error.new("Illegal method (#{method})") unless ConnMethods.include?(method)
        @conn.send(method,*args)
      end
      ConnMethods = [:rest_url,:get,:post]
    end
  end
end
