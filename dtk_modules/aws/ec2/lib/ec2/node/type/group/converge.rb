module DTKModule
  module Ec2::Node::Type
    class Group
      class Converge
        def initialize(parent, cardinalty, current_instances)
          @parent            = parent
          @cardinalty        = cardinalty
          @current_instances = current_instances
        end
        private :initialize

        # Both :alive and :terminated are InstanceInfo Arrays reflecting, added, or deleted elements
        Output = Struct.new(:alive, :terminated)
        # returns Output
        def self.converge_managed(parent, cardinalty, current_instances)
          new(parent, cardinalty, current_instances).converge_managed
        end
        def converge_managed
          num_existing  = current_instances.size
          if num_existing < cardinalty
            add_new_instances(cardinalty - num_existing)
          elsif num_existing > cardinalty
            delete_instances(num_existing - cardinalty)
          else
            Output.new(current_instances, [])
          end
        end

        private

        attr_reader :parent, :cardinalty, :current_instances

        # returns Output that includes existing and new instances
        def add_new_instances(count)
          Output.new(current_instances + parent.create_instances(count), []) 
        end

        # returns Output that includes remaining instances and terminated ones
        def delete_instances(count)
          instances_to_delete = current_instances.last(count) 
          parent.terminate_instances(Group.instance_ids(instances_to_delete))
          # remaining_instances under alive
          Output.new(current_instances.first(current_instances.size - count), instances_to_delete)
        end
        
      end
    end
  end
end
