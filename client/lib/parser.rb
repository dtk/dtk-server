module R8
  module Client
    def load_command(command_name)
      unless parser_adapter = Config[:cli_parser]
        raise Error.new("No cli parser specified in config file")
      end
      r8_nested_require("parser/adapters",parser_adapter)
      r8_nested_require("parser/adapters/parser_adapter",command_name)
    end
    module CommandBase
      def self.execute_from_cli(conn,argv)
        ret = start(argv,:conn => conn)
        ret.kind_of?(Response) ? ret : ResponseNoOp.new
      end

      def method_missing(method,*args)
        raise Error.new("Illegal method (#{method})") unless ConnMethods.include?(method)
        @conn.send(method,*args)
      end
      ConnMethods = [:rest_url,:get,:post]
    end
  end
end
