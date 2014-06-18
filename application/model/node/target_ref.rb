module DTK
  class Node
    # This refers to an object that is used to point to an existing node in a target; it is a peer of Node::Template
    class TargetRef < self
      
      #This creates if needed target refs and links nodes to them
      #TODO: now creating new ones as opposed to case where overlaying asssembly on existing nodes
      def self.create_linked_target_refs?(target,nodes)
        #TODO: temporary code where just do this for node_groups
        ndx_target_refs_needed = ndx_num_new_target_refs_needed(target,nodes)
        pp [:debug_ndx_target_refs_needed,ndx_target_refs_needed]
        return if ndx_target_refs_needed.empty?
        num_target_nodes_needed = nodes.inject(0){|r,n|r+n.attribute.cardinality}
Log.error('got here in work on creating linked target refs for node groups')
raise ErrorUsage.new('got here')
      end

      def self.process_import_nodes_input!(inventory_data_hash)
        inventory_data_hash.each_value do |input_node_hash|
          process_import_node_input!(input_node_hash)
        end
      end

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

     private
      #returns for each node that needs one or more target ref returns number; ndx is node id
      def self.ndx_num_new_target_refs_needed(target,nodes)
        ret = Hash.new

        #TODO: temporary; removes all nodes that are not node groups
        nodes = nodes.select{|n|n.is_node_group?()}
        return ret if nodes.empty?

        ndx_linked_target_ref_idhs = ndx_linked_target_ref_idhs(target,nodes)
        nodes.each do |node|
          node_id = node[:id]
          num_linked = (ndx_linked_target_ref_idhs[node_id]||[]).size 
          num_needed = node.attribute.cardinality - num_linked
          if num_needed > 0
            ret[node_id] = num_needed
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

      def self.process_import_node_input!(input_node_hash)
        unless host_address = input_node_hash["external_ref"]["routable_host_address"]
          raise Error.new("Missing field input_node_hash['external_ref']['routable_host_address']")
        end

        # for type use type from external_ref ('physical'), if not then use default type()
        type = input_node_hash["external_ref"]["type"] if input_node_hash["external_ref"]
        input_node_hash.merge!("type" => type||type())
        params = {"host_address" => host_address}
        input_node_hash.merge!(child_objects(params))
      end

      #TODO: collapse with application/utility/library_nodes - node_info
      def self.child_objects(params={})
        {
          "attribute"=> {
            "host_addresses_ipv4"=>{
              "required"=>false,
              "read_only"=>true,
              "is_port"=>true,
              "cannot_change"=>false,
              "data_type"=>"json",
              "value_derived"=>[params["host_address"]],
              "semantic_type_summary"=>"host_address_ipv4",
              "display_name"=>"host_addresses_ipv4",
              "dynamic"=>true,
              "hidden"=>true,
              "semantic_type"=>{":array"=>"host_address_ipv4"}
            },
            "fqdn"=>{
              "required"=>false,
              "read_only"=>true,
              "is_port"=>true,
              "cannot_change"=>false,
              "data_type"=>"string",
              "display_name"=>"fqdn",
              "dynamic"=>true,
              "hidden"=>true,
            },
            "node_components"=>{
              "required"=>false,
              "read_only"=>true,
              "is_port"=>true,
              "cannot_change"=>false,
              "data_type"=>"json",
              "display_name"=>"node_components",
              "dynamic"=>true,
              "hidden"=>true,
            }
          },
          "node_interface"=>{
            "eth0"=>{"type"=>"ethernet", "display_name"=>"eth0"}
          }
        }
      end
    end
  end
end
