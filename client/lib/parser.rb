module R8
  module Client
    def load_command(command_name)
      parser_adapter = Config[:cli_parser]|| "thor"
      r8_nested_require("parser/adapters",parser_adapter)
      r8_nested_require("commands/#{command_name}",parser_adapter)
    end
    module CommandBase
      def self.execute_from_cli(conn,argv)
        ret = start(argv,:conn => conn)
        ret.kind_of?(Response) ? ret : ResponseNoOp.new
      end

      def get(url)
        @conn.get(self.class,url)
      end
      def post(url,body=nil)
        @conn.post(self.class,url,body)
      end
      def rest_url(route)
        @conn.rest_url(route)
      end
    end
  end
end
