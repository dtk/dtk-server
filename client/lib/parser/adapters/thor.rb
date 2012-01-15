require 'thor'
module R8
  module Client
    class CommandBaseThor < ::Thor
      include CommandBase
      def initialize(args, opts, config)
        @conn = config[:conn]
        super
      end

      def self.execute_from_cli(conn,argv)
        ret = start(argv,:conn => conn)
        ret.kind_of?(Response) ? ret : ResponseNoOp.new
      end
    end
  end
end
