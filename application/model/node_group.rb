module XYZ
  class NodeGroup < Model
    set_relation_name(:node,:node_group)
    def self.up()
      column :dynamic_membership_sql, :json #sql where clause that picks out node members and means to ignore memebrship assocs
      virtual_column :member_id_list, :dependencies => {
        :node_group_member =>
        {:join_cond=>{:id=> :node_group_member__node_group_id},
          :cols=>[:id, :display_name, :ref, :ref_num, :node_id, :node_group_id]
        }}

      many_to_one :library, :datacenter, :project
    end

    ### virtual column defs
    def member_id_list()
      pp self
      self
    end
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

  class GroupGroupMember < Model
    set_relation_name(:node,:group_group_member)
    def self.up()
      foreign_key :parent_group_id, :node_group, FK_CASCADE_OPT
      foreign_key :child_group_id, :node_group, FK_CASCADE_OPT
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
