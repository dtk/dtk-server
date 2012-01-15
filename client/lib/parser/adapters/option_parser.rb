module R8
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

      def self.command_name()
        to_s.gsub(/^.*::/, '').gsub(/Command$/,'').scan(/[A-Z][a-z]+/).map{|w|w.downcase}.join("-")
      end
    end
  end
end
