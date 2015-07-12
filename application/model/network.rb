module XYZ
  class NetworkPartition < Model
    set_relation_name(:network, :partition)
    class << self
      def up
        ds_column_defs :ds_key
        column :is_deployed, :boolean, default: false
        column :is_internet, :boolean, default: false #TBD might replace with :type
        many_to_one :library, :datacenter
      end
    end
  end

  class NetworkGateway < Model
    set_relation_name(:network, :gateway)
    class << self
      def up
        ds_column_defs :ds_attributes, :ds_key
        column :is_deployed, :boolean, default: false
        foreign_key :network_partition1_id, :network_partition, FK_CASCADE_OPT
        foreign_key :network_partition2_id, :network_partition, FK_CASCADE_OPT
        many_to_one :library, :datacenter
      end
      ##### Actions
    end
  end

  # TBD: might move AddressAccessPoint to node or own model file
  class AddressAccessPoint < Model
    set_relation_name(:network, :address_access_point)
    class << self
      def up
        column :network_address, :json #e.g., {:family : "ipv4, :address : "10.4.5.7"} allow family: "dns" :address"
        column :type, :varchar, size: 25 #internet,local ..
        foreign_key :network_partition_id, :network_partition, FK_CASCADE_OPT
        many_to_one :node
      end
      ##### Actions
    end
  end
end
