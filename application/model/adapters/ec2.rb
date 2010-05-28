module XYZ
  module Adapter
    class EC2 < ModelAdapter
      def self.factory(model_class,hash_object)
        if model_class == Node
          require File.expand_path('ec2/node',File.dirname(__FILE__))
          EC2::Node.create_instance(hash_object)
        end
      end

      def self.adapt(model_object)      
        if model_object.kind_of?(Node)
          require File.expand_path('ec2/node',File.dirname(__FILE__))
          EC2::Node.new(model_object)
        end
      end
    end
  end
end
