module DTK; class Node
  class TargetRef
    class Input < Array
      r8_nested_require('input','element')
      r8_nested_require('input','inventory_data')
      r8_nested_require('input','base_nodes')

      def self.create_nodes_from_inventory_data(target, inventory_data)
        target_ref_hash = inventory_data.ret_target_ref_hash()
        target_idh = target.id_handle()
        Model.import_objects_from_hash(target_idh, {:node => target_ref_hash}, :return_info => true)
      end
      
      #This creates if needed target refs and links nodes to them
      #TODO: now creating new ones as opposed to case where overlaying asssembly on existing nodes
      def self.create_linked_target_refs?(target,assembly,nodes)
        #returns new idhs indexed by node (id) they linked to
        inventory_input = BaseNodes.new(target,assembly)
        TargetRef.num_target_refs_needed(target,nodes).each do |node_info|
          inventory_input.add!(node_info)
        end
        target_ref_hash = inventory_input.ret_target_ref_hash()
        target_idh = target.id_handle()
        Model.import_objects_from_hash(target_idh, {:node => target_ref_hash}, :return_info => true)
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
end; end

