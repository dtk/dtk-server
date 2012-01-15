require 'thor'
module R8
  module Client
    def load_command(command_name)
      r8_nested_require("command",command_name)
    end
    class CommandBase < ::Thor
      def initialize(args, opts, config)
        @conn = config[:conn]
        super
      end

      def self.execute_from_cli(conn,argv)
        start(argv,:conn => conn)
      end

      def method_missing(method,*args)
        raise Error.new("Illegal method (#{method})") unless ConnMethods.include?(method)
        @conn.send(method,*args)
      end
      ConnMethods = [:rest_url,:get,:post]
    end
  end
end
