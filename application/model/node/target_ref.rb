module DTK
  class Node
    # This refers to an object that is used to point to an existing node in a target; it is a peer of Node::Template
    class TargetRef < self
      def self.process_import_nodes_input!(inventory_data_hash)
        inventory_data_hash.each_value do |input_node_hash|
          process_import_node_input!(input_node_hash)
        end
      end

      #these are nodes without any assembly on them
      def self.get_free_nodes(target)
        sp_hash = {
          :cols => [:id, :display_name, :type, :assembly_id, :datacenter_datacenter_id, :managed],
          :filter => [:and, 
                        [:eq, :type, type()],
                        [:eq, :datacenter_datacenter_id, target[:id]], 
                        [:eq, :managed, true]]
        }
        node_mh = target.model_handle(:node)
        ret_unpruned = get_objs(node_mh,sp_hash)

        ndx_matched_target_refs = ndx_target_refs_matching_instances(ret_unpruned.map{|r|r.id_handle})
        if ndx_matched_target_refs.empty?
          return ret_unpruned
        end
        ret_unpruned.reject{|r|ndx_matched_target_refs[r[:id]]}
      end

     private
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
        input_node_hash.merge!("type" => type())
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
