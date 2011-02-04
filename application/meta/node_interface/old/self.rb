#    set_relation_name(:node,:interface)
    def self.up()
      super()
      return
      column :type, :varchar, :size => 25 #ethernet, vlan, ...
      column :address, :json #e.g., {:family : "ipv4, :address : "10.4.5.7", "mask" : 255.255.255.0"}
      foreign_key :network_partition_id, :network_partition, FK_CASCADE_OPT
      many_to_one :node, :node_interface
      one_to_many :node_interface
    end
