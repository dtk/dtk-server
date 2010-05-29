require File.expand_path("../ec2", File.dirname(__FILE__))
module XYZ
  module CloudProvider
    module Ec2
      class Node < Top 
        def self.discover_and_update(filter={})
          require 'pp'
          pp connection().servers_all()
          #TBD: next put in has from and call up to from hash; need attributes that are id test
        end
      end
    end
  end
end
