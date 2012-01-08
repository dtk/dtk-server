module R8
  module Client
    def load_command(command_name)
      #require File.expand_path("commands/#{command_name}", File.dirname(__FILE__))
      r8_nested_require("commands",command_name)
    end
    class CommandBase
      def initialize(conn)
        @conn = conn
      end

      def apply(subcommand,*args)
        method = subcommand.to_sym
        raise Error.new("Illegal subcommand #{subcommand||""}") unless respond_to?(method)
        send(method,*args)
      end

      def method_missing(method,*args)
        raise Error.new("Illegal method (#{method})") unless ConnMethods.include?(method)
        @conn.send(method,*args)
      end
      ConnMethods = [:rest_url,:get,:post]
    end
  end
end
