require 'rubygems'
require 'fog'
require 'fog/credentials'

module XYZ
  module CloudConnect
    class EC2
      def initialize()             
        @connection = Fog::AWS::EC2.new(Fog.credentials())
      end

      def servers_all()
        @connection.servers.all.map{|x|x.attributes}
      end
    end
  end
end
