module DTKModule
  class Ec2::Node::Type::Group
    INSTANCE_ID_KEY = :instance_id
    module InstanceIdMixin
      def instance_ids(instances)
        instances.map { |instance| instance_id?(instance) }.reject{ |instance_id| instance_id.nil? }
      end

      def instance_id?(instance)
        instance[INSTANCE_ID_KEY]
      end

      def instance_id(instance)
        instance_id?(instance) || fail("Unexepected that instance_id(instance) is nil") 
      end

    end
  end
end
