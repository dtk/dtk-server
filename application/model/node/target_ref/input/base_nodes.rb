module DTK; class Node; class TargetRef
  class Input 
    class BaseNodes < self
      # This creates if needed target refs and links nodes to them
      # returns new idhs indexed by node (id) they linked to
      # or if they exist their idhs
      def self.create_linked_target_refs?(target,assembly,nodes,opts={})
        ret = Hash.new
        if opts[:node_groups_only]
          nodes = nodes.select{|n|n.is_node_group?()}
        end
        if nodes.empty?
          return nodes
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
            el.add_target_ref_and_ngr!(create_objs_hash,target,assembly)
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

        # returns [target_ref,node_group_relation]
        def add_target_ref_and_ngr!(ret,target,assembly)
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
