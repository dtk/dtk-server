module DTK
  class Node
    # This refers to an object that is used to point to an existing node in a target; it is a peer of Node::Template
    class TargetRef < self
      r8_nested_require('target_ref','input')

      # these are nodes without any assembly on them
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

        ndx_matched_target_refs = ndx_target_refs_to_their_instances(ret_unpruned.map{|r|r.id_handle})
        if ndx_matched_target_refs.empty?
          return ret_unpruned
        end
        ret_unpruned.reject{|r|ndx_matched_target_refs[r[:id]]}
      end

      def self.create_nodes_from_inventory_data(target, inventory_data)
        Input.create_nodes_from_inventory_data(target, inventory_data)
      end

      # This creates if needed target refs and links nodes to them
      # returns new idhs indexed by node (id) they linked to
      # or if they exist their idhs
      def self.create_linked_target_refs?(target,assembly,nodes,opts={})
        Input::BaseNodes.create_linked_target_refs?(target,assembly,nodes,opts)
      end

      # returns hash of form {NodeInstanceId -> [target_refe_idh1,...],,}
      # filter can be of form
      #  {:node_instance_idhs => [idh1,,]}, or
      #  {:node_group_relation_idhs => [idh1,,]}
      def self.ndx_matching_target_refs(filter)
        ret = Hash.new
        filter_rel = sample_idh = nil
        if filter[:node_instance_idhs]
          idhs = filter[:node_instance_idhs]
          filter_rel = :node
        elsif filter[:node_group_relation_idhs]
          idhs = filter[:node_group_relation_idhs]
          filter_rel = :node_group_relation
        else
          raise Error.new("Unexpected filter: #{filter.inspect}")
        end
        if idhs.empty?
          return ret
        end

        #node_group_id matches on instance side and noe_id on target ref side
        sp_hash = {
          :cols => [:node_id,:node_group_id],
          :filter => [:oneof,filter_rel,idhs.map{|n|n.get_id}]
        }
        sample_idh = idhs.first
        target_ref_mh = sample_idh.createMH(:node)
        ngr_mh = sample_idh.createMH(:node_group_relation)
        Model.get_objs(ngr_mh,sp_hash).each do |r|
          node_id = r[:node_group_id]
          (ret[node_id] ||= Array.new) << target_ref_mh.createIDH(:id => r[:node_id])
        end
        ret
      end

     private
      # returns hash of form {TargetRefId => [matching_node_instance1,,],}
      def self.ndx_target_refs_to_their_instances(node_target_ref_idhs)
        ret = Hash.new
        return ret if node_target_ref_idhs.empty?
      # object model structure that relates instance to target refs is where instance's :canonical_template_node_id field point to target_ref
        sp_hash = {
          :cols => [:id, :display_name,:canonical_template_node_id],
          :filter => [:oneof,:canonical_template_node_id,node_target_ref_idhs.map{|idh|idh.get_id()}]
        }
Log.error("see why this is using :canonical_template_node_id and not node_group_relation")
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

      # TODO: collapse with application/utility/library_nodes - node_info
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
