module XYZ
  class NetworkPartition < Model
    set_relation_name(:network,:partition)
    class << self
      def up()
        column :is_deployed, :boolean
        column :is_internet, :boolean #TBD might replace with :type
        many_to_one :library,:project
        one_to_many :network_address, :network_address_access_point
      end
    end
  end

  class NetworkGateway < Model
    set_relation_name(:network,:gateway)
    class << self
      def up()
        column :vendor_attributes, :json
        column :is_deployed, :boolean
        foreign_key :network_partition1_id, :network_partition, FK_CASCADE_OPT
        foreign_key :network_partition2_id, :network_partition, FK_CASCADE_OPT
        many_to_one :library,:project
      end
      ##### Actions
    end
  end

  class NetworkAddress < Model
    set_relation_name(:network,:address)
    class << self
      def up()
	column :address, :varchar, :size => 30
        column :family, :varchar, :size => 10
  	column :info, :json #TBD for unstructuctured
        many_to_one :node_interface, :network_partition
      end
      ##### Actions
    end
  end

  class NetworkAddressAccessPoint < Model
    set_relation_name(:network,:address_access_point)
    class << self
      def up()
        foreign_key :network_address_id, :network_address, FK_CASCADE_OPT
        foreign_key :node_id, :node, FK_CASCADE_OPT
        many_to_one :network_partition
      end
      ##### Actions
    end
  end
end
