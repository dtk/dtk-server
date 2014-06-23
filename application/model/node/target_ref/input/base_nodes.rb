module DTK; class Node; class TargetRef
  class Input 
    class BaseNodes < self
      def initialize(target)
        super()
        @target = target
      end
      def add!(node_info)
        self << Element.new(@target,node_info)
      end
=begin
      {:node=>
        {:id=>2147543745,
   :display_name=>"slaves",
   :parent_id=>2147484434,
   :ancestor_id=>2147539902,
   :assembly_id=>2147543744,
   :node_template_id=>2147522122,
   :external_ref=>
          {:image_id=>"ami-fce20e94", :type=>"ec2_image", :size=>"t1.micro"},
   :type=>"node_group_staged",
          :attribute_value_cache=>{:cardinality=>3}},
 :num_needed=>3,
        :num_linked=>0}
=end      
      class Element 
        def initialize(target,node_info)
          @target = target
          @node = node_info[:node]
          @num_needed = node_info[:num_needed]
          @num_linked = node_info[:num_linked]
        end
        
        #TODO: just copied from inventory; must change
        def ret_target_ref_hash()
          ret = Hash.new
pp [:ret_target_ref_hash,self]
          unless display_name = @node.get_field?(:display_name)
            raise Error.new("Unexpected that that node has no name field")
          end
          unless @node.external_ref.references_image?(@target)
            raise ErrorUsage.new("Node (#{display_name}) is not in target taht supports node creation or does not have needed info")
          end
          raise ErrorUsage.new('got here')
          #(@num_linked+1..@num_linked+@num_needed).ecah do |index|

          ret_hash = merge('display_name' => Input.ret_display_name(@type,name))
          

          ret_hash.merge!(:type => external_ref['type']||TargetRef.type())
          
          host_address = nil
          if @type == :physical
            unless host_address = external_ref['routable_host_address']
              raise Error.new("Missing field input_node_hash['external_ref']['routable_host_address']")
            end
          end
          params = {"host_address" => host_address}
          ret_hash.merge!(Input.child_objects(params))
          ref = Input.ret_ref(@type,name)
          pp [{ref => ret_hash}]
          raise ErrorUsage.new('got here')
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



