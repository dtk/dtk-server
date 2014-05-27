module DTK
  class Node
    # This refers to an object that is used to point to an existing node in a target; it is a peer of Node::Template
    class TargetRef < self
      def self.process_import_nodes_input!(inventory_data_hash)
raise 'got here'
        inventory_data_hash.each_value do |input_node_hash|
          process_import_node_input!(input_node_hash)
        end
      end
      private
      def self.import_nodes(input_node_hash)
      end
    end
  end
end
      # def self.parse_inventory_file(target_id)
      #   config_base = Configuration.instance.default_config_base()
      #   inventory_file = "#{config_base}/inventory.yaml"

      #   hash = YAML.load_file(inventory_file)
      #   ret = Hash.new

      #   hash["nodes"].each do |node_name, data|
      #     display_name = data["name"]||node_name
      #     ref = "physical--#{display_name}"
      #     ret[ref] = {
      #       :os_identifier => data["type"],
      #       :display_name => display_name,
      #       :os_type => data["os_type"],
      #       :managed => false,
      #       :external_ref => {:type => "physical", :routable_host_address => node_name, :ssh_credentials => data["ssh_credentials"]}
      #     }
      #   end

      #   ret
      # end

=begin
 "physical--node4"=>
  {"display_name"=>"node4",
   "os_type"=>"centos",
   "managed"=>"false",
   "external_ref"=>
  {"type"=>"physical",
     "routable_host_address"=>"192.168.200.4",
    "ssh_credentials"=>{"ssh_user"=>"ubuntu", "ssh_password"=>"foo"}}}}
    display_name     | data_type |         semantic_type          | semantic_type_summary | read_only | dynamic | cannot_change | required | hidden | is_port



dtk101=# select ref,display_name, external_ref,type,os_type,os_identifier,admin_op_status from node.node where id = 2147522147;
         ref          |  display_name   |                            external_ref                            | type  | os_type | os_identifier | admin_op_status
----------------------+-----------------+--------------------------------------------------------------------+-------+---------+---------------+-----------------
 ami-c84ba8a0-2xlarge | Precise 2xlarge | {"image_id":"ami-fce20e94","type":"ec2_image","size":"c3.2xlarge"} | image | ubuntu  | precise       | pending
(1 row)


dtk101=# select relation_id, uri from top.id_info where uri ~ '/library/public/node/ami-c84ba8a0-2xlarge/' and not relation_id is null order by uri;
 relation_id |                                   uri
-------------+-------------------------------------------------------------------------
  2147522149 | /library/public/node/ami-c84ba8a0-2xlarge/attribute/fqdn
  2147522148 | /library/public/node/ami-c84ba8a0-2xlarge/attribute/host_addresses_ipv4
  2147522150 | /library/public/node/ami-c84ba8a0-2xlarge/attribute/node_components
  2147522151 | /library/public/node/ami-c84ba8a0-2xlarge/node_interface/eth0
(4 rows)


---------------------+-----------+--------------------------------+-----------------------+-----------+---------+---------------+----------+--------+---------
 host_addresses_ipv4 | json      | {":array":"host_address_ipv4"} | host_address_ipv4     | t         | t       | f             | f        | t      | t
 fqdn                | string    |                                |                       | t         | t       | f             | f        | t      | t
 node_components     | json      |                                |                       | t         | t       | f             | f        | t      | t
(3 rows)
dtk101=# select display_name,type from node.interface where id in (2147522151);
 display_name |   type
--------------+----------
 eth0         | ethernet
=end
