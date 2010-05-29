module XYZ
  module CloudProvider
    module Ec2
      class Node 
        def self.discover_and_update(filer={})
          require 'pp'
          pp CloudConnect::EC2.new.servers_all()
          #TBD: next put in has from and call up to from hash; need attributes that are id test
        end
      end
    end
  end
end
