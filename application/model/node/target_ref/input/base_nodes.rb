module DTK; class Node; class TargetRef
  class Input 
    class BaseNodes < self
      def add!(node_info)
        self << Element.new(node_info)
      end
      class Element < Hash
        def initialize(node_info)
          super()
          replace(node_info)
        end
      end
    end
  end
end; end; end

=begin
      def self.create_linked_nodes(target,node,num_needed,num_linked)
        target_id = target.id
        base_display_name = node.get_field?(:disply_name)
        base_ref = node.get_field?(:ref)
        create_rows = (num_linked+1..num_linked+num_needed).map do |index|
          {
            :ref => "#{base_ref}--#{index}",
            :display_name => "#{base_display_name}--#{index}",
            :managed => true,
            :datacenter_datacenter_id => target_id,
            #TODO: stub for garbage collection
            :type => 'garb'
         }
        end

        #for create model handle needs parent
        node_mh = target.model_handle().create_childMH(:node) 
#        new_target_refs = create_from_rows(attr_link_mh,new_link_rows)
pp [:debug_creating,create_rows]
      end

=end



