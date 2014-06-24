module DTK
  class Node
    # This refers to an object that is used to point to an existing node in a target; it is a peer of Node::Template
    class TargetRef < self
      r8_nested_require('target_ref','input')

      #these are nodes without any assembly on them
      def self.get_free_nodes(target)
        sp_hash = {
          :cols => [:id, :display_name, :ref, :type, :assembly_id, :datacenter_datacenter_id, :managed],
          :filter => [:and, 
                        [:eq, :type, type()],
                        [:eq, :datacenter_datacenter_id, target[:id]], 
                        [:eq, :managed, true]]
        }
        node_mh = target.model_handle(:node)
        ret_unpruned = get_objs(node_mh,sp_hash,:keep_ref_cols => true)

        ndx_matched_target_refs = ndx_target_refs_matching_instances(ret_unpruned.map{|r|r.id_handle})
        if ndx_matched_target_refs.empty?
          return ret_unpruned
        end
        ret_unpruned.reject{|r|ndx_matched_target_refs[r[:id]]}
      end

      def self.create_nodes_from_inventory_data(target, inventory_data)
        Input.create_nodes_from_inventory_data(target, inventory_data)
      end
      def self.create_linked_target_refs?(target,assembly,nodes)
        Input.create_linked_target_refs?(target,assembly,nodes)
      end

     private      
      #returns for each node that needs one or more target refs the following hash
      # :node
      # :num_needed
      # :num_linked
      def self.num_target_refs_needed(target,nodes)
        ret = Array.new
        #TODO: temporary; removes all nodes that are not node groups
        nodes = nodes.select{|n|n.is_node_group?()}
        return ret if nodes.empty?
        ndx_linked_target_ref_idhs = ndx_linked_target_ref_idhs(target,nodes)
        nodes.each do |node|
          node_id = node[:id]
          num_linked = (ndx_linked_target_ref_idhs[node_id]||[]).size 
          num_needed = node.attribute.cardinality - num_linked
          if num_needed > 0
            ret << {:node => node,:num_needed => num_needed,:num_linked => num_linked}
          else num_needed < 0
            Log.error("Unexpected that number of target refs (#{num_linked}) for (#{node[:display_name].to_s}) is graeter than cardinaility (#{node.attribute.cardinality.to_s})")
          end
        end
        ret
      end

      #indexed by node id
      def self.ndx_linked_target_ref_idhs(target,nodes)
        ret = Hash.new
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:node_id,:node_group_id],
          :filter => [:and, 
                      [:oneof,:node_group_id,nodes.map{|n|n.id}],
                      [:eq,:datacenter_datacenter_id,target.id]]
        }
        node_mh = target.model_handle(:node)
        get_objs(target.model_handle(:node_group_relation),sp_hash).each do |r|
          (ret[r[:node_group_id]] ||= Array.new) << node_mh.createIDH(:id => r[:node_id])
        end
      end

      #returns hash of form {TargetRefId => [matching_node_insatnce1,,],}
      def self.ndx_target_refs_matching_instances(node_target_ref_idhs)
        ret = Hash.new
        return ret if node_target_ref_idhs.empty?
        
      # object model structure that relates instance to target refs is where instance's :canonical_template_node_id field point to target_ref
        sp_hash = {
          :cols => [:id, :display_name,:canonical_template_node_id],
          :filter => [:oneof,:canonical_template_node_id,node_target_ref_idhs.map{|idh|idh.get_id()}]
        }
        node_mh = node_target_ref_idhs.first.createMH()
        get_objs(node_mh,sp_hash).each do |r|
          (ret[r[:canonical_template_node_id]] ||= Array.new) << r
        end
        ret
      end

      def self.type()
        TypeField
      end
      TypeField = 'target_ref'
    end
  end
end
