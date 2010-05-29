require File.expand_path("../ec2", File.dirname(__FILE__))
module XYZ
  module CloudProvider
    module Ec2
      class Node < Top 
        def self.discover_and_update(filter={})
          nodes = connection().servers_all()
          require 'pp'; pp nodes
=begin
TBD: logic to put in 
         nodes.each do |n|
           id_handle = find_object(n)
           if id_handle
             update_object(id_handle,n)
           else
             create_object(n)
           end
         end
=end
        end
       private
        def unique_keys
          [:image_id]
        end
      end
    end
  end
end
