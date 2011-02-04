#    set_relation_name(:datacenter,:datacenter)
    def self.up()
      # no table specific columns (yet)
      one_to_many :data_source, :node, :state_change, :node_group, :node_group_member, :attribute_link, :network_partition, :network_gateway, :component
    end
