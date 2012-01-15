module R8
  module Client
    class CommandBaseOptParse
      include CommandBase
      def initialize(conn)
        @conn = conn
      end

      def execute_from_cli(argv)
        method, args_hash = OptionParser.parse_options(self.class,argv)
        raise Error.new("Illegal subcommand #{subcommand||""}") unless respond_to?(method)
        if @conn.connection_error
          return @conn.connection_error
        end
        send(method,args_hash)
      end

      def self.command_name()
        to_s.gsub(/^.*::/, '').gsub(/Command$/,'').scan(/[A-Z][a-z]+/).map{|w|w.downcase}.join("-")
      end
    end
  end
end
