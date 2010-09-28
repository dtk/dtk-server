module XYZ
  class NodeGroup < Model
    set_relation_name(:node,:node_group)
    def self.up()
      column :dynamic_membership_sql, :json #sql where clause that picks out node members and means to ignore memebrship assocs
      virtual_column :member_id_list, :dependencies => 
        [
         {:model_name => :node_group_member,
           :join_cond=>{:node_group_id => :id},
           :cols=>[:id, :display_name, :ref, :ref_num, :node_id, :node_group_id]
         },
         {:model_name => :node,
           :join_cond=>{:id => :node_id}
         }
        ]

      many_to_one :library, :datacenter, :project
    end

    ### virtual column defs
    def member_id_list()
      (self[:node]||[]).map{|n|n[:id]}
    end

    #######################
    ### object access functions
    #######################
    #need to overwrite this fn because special processing to handle :dynamic_membership_sql
    def self.get_objects_and_related_objects(model_handle,where_clause={},opts={})
      #break into two parts; one with explicit links and the other with :dynamic_membership_sql non null
      static_group = super(model_handle,SQL.and(where_clause,{:dynamic_membership_sql => nil}),opts)
      static_group + get_objects_and_related_objects_dyanmic(model_handle,where_clause,opts)
    end
   private

    def self.get_objects_and_related_objects_dyanmic(model_handle,where_clause={},opts={})
      #TODO: make more efficient
      c = model_handle[:c]
      groups_info = get_objects(model_handle,SQL.and(where_clause,SQL.and(where_clause,SQL.not(:dynamic_membership_sql => nil))),
                                opts.merge(:field_set => [:id,:display_name,:dynamic_membership_sql]))
      groups_info.map{|group|group.merge :node => get_objects(ModelHandle.new(c,:node),group[:dynamic_membership_sql])}
        
    end
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
