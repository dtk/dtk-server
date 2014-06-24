#    set_relation_name(:library,:library)
    def self.up()
      # no table specfic fields (yet)
      one_to_many :component, :node, :component_def, :node_group, :node_group_member, :attribute_link, :network_partition, :network_gateway, :region,:assoc_region_network, :data_source, :search_object
    end
