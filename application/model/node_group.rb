module XYZ
  class NodeGroup < Model
    set_relation_name(:node,:node_group)
    def self.up()
      column :dynamic_membership_sql, :json #sql where clause that picks out node members and means to ignore memebrship assocs
      virtual_column :member_id_list
      many_to_one :library, :datacenter, :project
      one_to_many :component
    end

    ### virtual column defs
    def member_id_list()
      (self[:node]||[]).map{|n|n[:id]}
    end
    #######################
    ### object procssing and access functions
    #object processing and access functions
    def self.clone_post_copy_hook(new_id_handle,target_id_handle,opts={})

      #create a change pending item associated with component created on the node group adn returns its id (so it can be
      # used as parent to change items for components on all the node groups memebrs
#      parent_pending_id = create_pending_change_item(new_id_handle,target_id_handle)
      parent_pending_id = PendingChangeItem.create_items([new_id_handle],target_id_handle)
      
      node_group_obj = get_object(target_id_handle)
      targets = ((node_group_obj||{})[:member_id_list]||[]).map{|node_id|target_id_handle.createIDH({:model_name => :node,:id=> node_id})}
      return Array.new if  targets.empty?
      recursive_override_attrs={
        :attribute => {
          :value_derived => :value_asserted,
          :value_asserted => nil
        }
      }
      new_cmp_id_handles = clone_copy(new_id_handle,targets,recursive_override_attrs)

=begin
      #put in attribute links
      node_cmp_wc = {:ancestor_id => new_id_handle.get_id()}
      node_cmp_fs = FieldSet.opt([:id])
      node_cmp_ds = get_objects_just_dataset(ModelHandle.new(c,:component),node_cmp_wc,node_cmp_fs)

      node_attr_fs = FieldSet.opt([:component_component_id,:id,:ref])
      node_attr_ds = get_objects_just_dataset(ModelHandle.new(c,:attribute),nil,node_attr_fs)

      group_attr_wc = {:component_component_id => new_id_handle.get_id()}
      group_attr_fs = FieldSet.opt([:id,:ref])
      group_attr_ds = get_objects_just_dataset(ModelHandle.new(c,:attribute),group_attr_wc,group_attr_fs)

      graph = node_cmp_ds.graph(:inner,node_attr_ds,{:component_component_id => :id}).graph(:inner,group_attr_ds,{:ref => :ref})
      select = graph.select('attribute_link',:attribute2__id,:attribute__id)
      #TODO: must also put in parent_relation
      create_from_select(ModelHandle.new(c,:attribute_link),FieldSet.new([:ref,:input_id,:output_id]),select)
      #TODO: links for monitor_items
=end
    end

    def self.create_pending_change_item(new_id_handle,target_id_handle)
      parent_id_handle = target_id_handle.get_parent_id_handle()
      ref = "pending_change_item"
      create_hash = {
        :pending_change_item => {
          ref => {
            :display_name => ref,
            :change => "new_component",
            :component_id => new_id_handle.get_id()
          }
        }
      }
      create_from_hash(parent_id_handle,create_hash).map{|x|x[:id]}.first
    end
    #######################

    #needed to overwrite this fn because special processing to handle :dynamic_membership_sql
    def self.get_objects(model_handle,where_clause={},opts={})
      #break into two parts; one with explicit links and the other with :dynamic_membership_sql non null
      static = get_objects_static(model_handle,where_clause,opts)
      dynamic = get_objects_dynamic(model_handle,where_clause,opts)
      static + dynamic
    end
   private
    def self.get_objects_static(model_handle,where_clause={},opts={})
      c = model_handle[:c]
      #important that Model.get_objects called, not get_objects
      #below returns just scalar attributes
      ng = Model.get_objects(model_handle,SQL.and(where_clause,{:dynamic_membership_sql => nil}),opts)
      return ng if ng.empty?
      #TODO: encapsulate this pattern to nest multiple matches; might have a variant of graph that does this
      ng_member_wc = SQL.or(*ng.map{|x|{:node_group_id => x[:id]}})
      ng_member_fs = FieldSet.opt([:node_group_id,:node_id])
      ng_members = Model.get_objects(ModelHandle.new(c,:node_group_member),ng_member_wc,ng_member_fs)
      cache = Hash.new
      ng_members.each do |el|
        #TODO: may change teh model class contsructors to take a model class
        node_obj = Node.new({:id => el[:node_id]},c,:node)
        if cache[el[:node_group_id]]
          cache[el[:node_group_id]][:node] << node_obj
        else
          cache[el[:node_group_id]] = ng.find{|x|x[:id] == el[:node_group_id]}
          cache[el[:node_group_id]][:node] = [node_obj]
        end
      end
      cache.values
    end

    def self.get_objects_dynamic(model_handle,where_clause={},opts={})
      #TODO: make more efficient
      c = model_handle[:c]
      #important that Model.get_objects called, not get_objects
      groups_info = Model.get_objects(model_handle,SQL.and(where_clause,SQL.and(where_clause,SQL.not(:dynamic_membership_sql => nil))),
                                opts.merge(FieldSet.opt([:id,:display_name,:dynamic_membership_sql])))
      groups_info.map{|group|group.merge :node => Model.get_objects(ModelHandle.new(c,:node),group[:dynamic_membership_sql])}
        
    end
  end

  class NodeGroupMember < Model
    set_relation_name(:node,:node_group_member)
    def self.up()
      column :is_elastic_node, :boolean, :default => false
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
