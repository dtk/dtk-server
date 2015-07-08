module XYZ
  class Region < Model
    set_relation_name(:region,:region)
    class << self
      def up
        column :ds_attributes, :json
        column :is_deployed, :boolean, default: false
        column :type, :varchar, size: 25 #type is availability_zone, datacenter, vdc
        one_to_many :region
        many_to_one :library
      end
    end
  end
  # TBD: do not include association between region gateway and network region of node since this is inferede through theer connection to a network partition; this also allows for more advanced models where node or gateway spans two differnt regions
  class AssocRegionNetwork < Model
    set_relation_name(:region,:assoc_network_partition)
    class << self
      def up
        foreign_key :network_partition_id, :network_partition, FK_CASCADE_OPT
        foreign_key :region_id, :region, FK_CASCADE_OPT
        many_to_one :library
      end
    end
  end
end
