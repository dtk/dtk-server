module XYZ
  module CloudProvider
    module Ec2
      class Node 
        def self.discover()
          require 'pp'
          pp CloudConnect::EC2.new.servers_all()
        end
      end
    end
  end
end
