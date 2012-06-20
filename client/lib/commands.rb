module DTK
  module Client
    def load_command(command_name)
      parser_adapter = Config[:cli_parser]|| "thor"
      dtk_nested_require("parser/adapters",parser_adapter)
      dtk_nested_require("commands/#{command_name}",parser_adapter)
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

      def self.handle_argument_error(task, error) 
        super
      end

     private
      def pretty_print_cols()
        self.class.pretty_print_cols()
      end
    end
  end
end
