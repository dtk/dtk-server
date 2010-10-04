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
      one_to_many :component
    end

    ### virtual column defs
    def member_id_list()
      (self[:node]||[]).map{|n|n[:id]}
    end

    #######################
    ### object procssing and access functions
    def self.clone_post_copy_hook(new_id_handle,target_id_handle)
      c = new_id_handle[:c]
      obj_on_node_group = get_object_deep(new_id_handle)
      #clone component(deep) on to all members
      #TODO: for efficiency handle by less sql operations
      node_group_obj = get_object(target_id_handle)
      (node_group_obj||{})[:member_id_list].each do |node_id|
        #TODO: need processing that checks if component already on node for components that can only be once on node
        clone(new_id_handle,IDHandle[:c => c,:model_name => :node,:id=> node_id],{},{:source_obj => obj_on_node_group})
      end
      #put in attribute links
      node_cmp_wc = {:ancestor_id => new_id_handle.get_id()}
      node_cmp_fs = {:field_set => [:id]}
      node_cmp_ds = get_objects_just_dataset(ModelHandle.new(c,:component),node_cmp_wc,node_cmp_fs)

      node_attr_fs = {:field_set => [:component_component_id,:id,:ref]}
      node_attr_ds = get_objects_just_dataset(ModelHandle.new(c,:attribute),nil,node_attr_fs)

      group_attr_wc = {:component_component_id => new_id_handle.get_id()}
      group_attr_fs = {:field_set => [:id,:ref]}
      group_attr_ds = get_objects_just_dataset(ModelHandle.new(c,:attribute),group_attr_wc,group_attr_fs)

      graph = node_cmp_ds.graph(:inner,node_attr_ds,{:component_component_id => :id}).graph(:inner,group_attr_ds,{:ref => :ref})
      select = graph.select('attribute_link',:attribute2__id,:attribute__id)
      create_from_select(ModelHandle.new(c,:attribute_link),[:ref,:input_id,:output_id],select)
      #TODO: links for monitor_items

    end
    #######################

    #needed to overwrite this fn because special processing to handle :dynamic_membership_sql
    def self.get_objects(model_handle,where_clause={},opts={})
      #break into two parts; one with explicit links and the other with :dynamic_membership_sql non null
      static_group = super(model_handle,SQL.and(where_clause,{:dynamic_membership_sql => nil}),opts)
      static_group + get_objects_dynamic(model_handle,where_clause,opts)
    end
   private

    def self.get_objects_dynamic(model_handle,where_clause={},opts={})
      #TODO: make more efficient
      c = model_handle[:c]
      #importnat bloe wthat  Model.get_objects called, not get_objects
      groups_info = Model.get_objects(model_handle,SQL.and(where_clause,SQL.and(where_clause,SQL.not(:dynamic_membership_sql => nil))),
                                opts.merge(:field_set => [:id,:display_name,:dynamic_membership_sql]))
      groups_info.map{|group|group.merge :node => Model.get_objects(ModelHandle.new(c,:node),group[:dynamic_membership_sql])}
        
    end
  end

  class NodeGroupMember < Model
    set_relation_name(:node,:node_group_member)
    column :is_elastic_node, :boolean, :default => false
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
end
