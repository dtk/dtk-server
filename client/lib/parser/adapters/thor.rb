require 'thor'
module DTK
  module Client
    class CommandBaseThor < ::Thor
      include CommandBase
      def initialize(args, opts, config)
        @conn = config[:conn]
        super
      end

      def self.execute_from_cli(conn,argv)
        return conn.connection_error if conn.connection_error
        ret = start(argv,:conn => conn)
        ret.kind_of?(Response) ? ret : ResponseNoOp.new
      end

      desc "help [SUBCOMMAND]", "Describes available subcommands or one specific subcommand"
      def help(*args)
        super
      end
    end
  end
end
