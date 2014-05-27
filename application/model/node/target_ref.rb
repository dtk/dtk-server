module DTK
  class Node
    # This refers to an object that is used to point to an existing node in a target; it is a peer of Node::Template
    class TargetRef < self
      def self.process_import_nodes_input!(inventory_data_hash)
        inventory_data_hash.each_value do |input_node_hash|
          process_import_node_input!(input_node_hash)
        end
      end
     private
      def self.process_import_node_input!(input_node_hash)
        unless host_address = input_node_hash["external_ref"]["routable_host_address"]
          raise Error.new("Missing field input_node_hash['external_ref']['routable_host_address']")
        end
        input_node_hash.merge!("type" => TypeField)
        params = {"host_address" => host_address}
        input_node_hash.merge!(child_objects(params))
      end
      TypeField = 'target_ref'
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
