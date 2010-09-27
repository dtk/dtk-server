module XYZ
  class NodeGroup < Model
    set_relation_name(:node,:node_group)
    def self.up()
      many_to_one :library, :datacenter, :project
    end

    ### virtual column defs
    #######################
    ### object access functions
    #######################
  end

  class NodeGroupMember < Model
    set_relation_name(:node,:node_group_member)
    def self.up()
      foreign_key :node_id, :node, FK_CASCADE_OPT
      foreign_key :node_group_id, :node_group, FK_CASCADE_OPT
      many_to_one :library, :datacenter, :project
    end

    ### virtual column defs
    #######################
    ### object access functions
    #######################
  end

  class AssocNodeGroupComponent < Model
    set_relation_name(:node,:assoc_group_component)
    def self.up()
      foreign_key :node_group_id, :node_group, FK_CASCADE_OPT
      foreign_key :component_id, :component, FK_CASCADE_OPT
      many_to_one :library, :datacenter, :project
    end

    ### virtual column defs
    #######################
    ### object access functions
    #######################
    end
end
