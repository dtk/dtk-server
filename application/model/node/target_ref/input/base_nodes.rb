module DTK; class Node; class TargetRef
  class Input 
    class BaseNodes < self
      def self.create_linked_target_ref?(target,node,assembly)
        ndx_node_target_ref_array = create_linked_target_refs?(target,assembly,[node])
        unless target_ref_array = ndx_node_target_ref_array[node[:id]]
          raise Error.new("Unexpected that create_linked_target_ref does not return element matching node[:id]")
        end
        unless target_ref_array.size == 1
          raise Error.new("Unexpected that ndx_node_target_ref_array.size not equal 1")
        end
        target_ref_array.first.create_object()
      end


      # This creates if needed target refs and links nodes to them
      # returns new idhs indexed by node (id) they linked to
      # or if they exist their idhs
      def self.create_linked_target_refs?(target,assembly,nodes,opts={})
        Log.error("deprecate this for create_target_refs_and_links?")
=begin
might have option to force calculation; otherwise; we want to eitehr link to new target refs or existing ones dependeing on whether nodes.map{|n|n[:node_template_id] point to target refs; might pass this in seperately
also need to fix ref key for node group relation so can have multiple things pointing to same target ref
=end
#nodes.map{|n|n.update_object!(:node_template_id)}
        ret = Hash.new
        if opts[:node_groups_only]
          nodes = nodes.select{|n|n.is_node_group?()}
        end
        if nodes.empty?
          return ret
        end
        ndx_target_ref_idhs = TargetRef.ndx_matching_target_ref_idhs(:node_instance_idhs => nodes.map{|n|n.id_handle})

        create_objs_hash = Hash.new
        nodes.each do |node|
          node_id = node[:id]
          cardinality = node.attribute.cardinality
          target_ref_idhs = ndx_target_ref_idhs[node_id]||[]
          num_needed = cardinality - target_ref_idhs.size
          if num_needed > 0
            el = Element.new(:node => node,:num_needed => num_needed)
            el.add_target_ref_and_ngr!(create_objs_hash,target,assembly,opts)
          elsif num_needed == 0
            if cardinality > 0
              ret.merge!(node_id => target_ref_idhs)
            end
          else # num_needed < 0
            Log.error("Unexpected that more target refs than needed")
            ret.merge!(node_id => target_ref_idhs)
          end
        end

        unless create_objs_hash.empty?
          all_idhs = Model.input_hash_content_into_model(target.id_handle(),create_objs_hash,:return_idhs => true)
          #all idhs have both nodes and node_group_rels
          ngr_idhs = all_idhs.select{|idh|idh[:model_name] == :node_group_relation}
          ret.merge!(TargetRef.ndx_matching_target_ref_idhs(:node_group_relation_idhs => ngr_idhs))
        end
        ret
      end

      def self.create_target_refs_and_links?(target,assembly,annotated_nodes)
pp [:annotated_nodes,annotated_nodes]
raise Error.new('got here')
        ret = Hash.new

        if nodes.empty?
          return ret
        end
        ndx_target_ref_idhs = TargetRef.ndx_matching_target_ref_idhs(:node_instance_idhs => nodes.map{|n|n.id_handle})

        create_objs_hash = Hash.new
        nodes.each do |node|
          node_id = node[:id]
          cardinality = node.attribute.cardinality
          target_ref_idhs = ndx_target_ref_idhs[node_id]||[]
          num_needed = cardinality - target_ref_idhs.size
          if num_needed > 0
            el = Element.new(:node => node,:num_needed => num_needed)
            el.add_target_ref_and_ngr!(create_objs_hash,target,assembly,opts)
          elsif num_needed == 0
            if cardinality > 0
              ret.merge!(node_id => target_ref_idhs)
            end
          else # num_needed < 0
            Log.error("Unexpected that more target refs than needed")
            ret.merge!(node_id => target_ref_idhs)
          end
        end

        unless create_objs_hash.empty?
          all_idhs = Model.input_hash_content_into_model(target.id_handle(),create_objs_hash,:return_idhs => true)
          #all idhs have both nodes and node_group_rels
          ngr_idhs = all_idhs.select{|idh|idh[:model_name] == :node_group_relation}
          ret.merge!(TargetRef.ndx_matching_target_ref_idhs(:node_group_relation_idhs => ngr_idhs))
        end
        ret
      end

      class Element 
        include ElementMixin
        attr_reader :node,:num_needed
        def initialize(node_info)
          @node = node_info[:node]
          @num_needed = node_info[:num_needed]
          @type = :base_node_link
        end

        def add_target_ref_and_ngr!(ret,target,assembly,opts={})
          target_ref_hash = ret_target_ref_hash(target,assembly)
          unless target_ref_hash.empty?
            (ret[:node] ||= Hash.new).merge!(target_ref_hash)
            node_group_rel_hash = target_ref_hash.keys.inject(Hash.new) do |h,node_ref|
              hash = {
                "node_group_id" => @node.id,
                "*node_id" => "/node/#{node_ref}"
              }
              ref = node_ref
              h.merge(ref => hash)
            end
            (ret[:node_group_relation] ||= Hash.new).merge!(node_group_rel_hash)
          end
          ret
        end

        def ret_target_ref_hash(target,assembly)
          ret = Hash.new
          unless display_name = @node.get_field?(:display_name)
            raise Error.new("Unexpected that that node has no name field")
          end
          external_ref = @node.external_ref
          unless external_ref.references_image?(target)
            raise ErrorUsage.new("Node (#{display_name}) is not in target that supports node creation or does not have needed info")
          end
          (1..@num_needed).inject(Hash.new) do |h,index|
            hash = {
              :display_name => ret_display_name(display_name,:index => index,:assembly => assembly),
              :type => TargetRef.type(),
              :external_ref => external_ref.hash() 
            }          
            ref = ret_ref(display_name,:index => index,:assembly => assembly)
            h.merge(ref => hash)
          end
        end
      end
    end
  end
end; end; end
