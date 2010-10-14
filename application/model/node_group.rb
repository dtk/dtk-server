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
    def self.add_model_specific_override_attrs!(override_attrs)
      override_attrs[:display_name] = SQL::ColRef.qualified_ref
    end

    def self.clone_post_copy_hook(new_id_handle,target_id_handle,opts={})

      #create a change pending item associated with component created on the node group adn returns its id (so it can be
      # used as parent to change items for components on all the node groups memebrs
      parent_pending_id = create_pending_change_item(new_id_handle,target_id_handle)
      
      node_group_obj = get_object(target_id_handle)
      targets = ((node_group_obj||{})[:member_id_list]||[]).map{|node_id|target_id_handle.createIH({:model_name => :node,:id=> node_id})}
      return Array.new if  targets.empty?
      recursive_override_attrs={
        :attribute => {
          :value_derived => :value_asserted,
          :value_asserted => nil
        }
      }
      new_cmp_ids = clone_copy(new_id_handle,targets,recursive_override_attrs)

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

    def self.old_clone_post_copy_hook(new_id_handle,target_id_handle,opts={})
      #create a change pending item associated with component created on the node group adn returns its id (so it can be
      # used as parent to change items for components on all the node groups memebrs
      parent_pending_id = create_pending_change_item(new_id_handle,target_id_handle)

      #first create all the components on nodes that are members of the  node_group
      node_group_obj = get_object(target_id_handle)
      member_id_list = node_group_obj[:member_id_list]
      return nil unless member_id_list and not member_id_list.empty?
      Aux::benchmark("multi insert"){test1(new_id_handle,member_id_list)}
    end

    def self.test1(source_id_handle,member_id_list)
      #TODO: abstract adn encas[pulate pattern below which copies to a set from a source object
      model_name = source_id_handle[:model_name]

      source_parent_model_name = :node_group #TODO: hardwired
      source_model_handle = source_id_handle.createMH(:parent_model_name => source_parent_model_name)
      source_parent_id_col = source_model_handle.parent_id_field_name()

      target_parent_model_name = :node #TODO: hardwired
      target_model_handle = source_id_handle.createMH(:parent_model_name => target_parent_model_name)
      target_parent_id_col = target_model_handle.parent_id_field_name()

      parent_ds = SQL::ArrayDataset.create(db,member_id_list.map{|x|{target_parent_id_col => x}},:parent)

      source_wc = {:id => source_id_handle.get_id()}
      field_set_to_copy = FieldSet.all_real(model_name).remove_cols(*([:id,:local_id]+[source_parent_id_col]))
      source_fs = FieldSet.opt(field_set_to_copy.remove_cols(target_parent_id_col))
      source_ds = get_objects_just_dataset(source_model_handle,source_wc,source_fs)

      graph = parent_ds.graph(:inner,source_ds)
      
      dups_allowed_for_cmp = false #TODO stub
      create_opts = {:duplicate_refs => dups_allowed_for_cmp ? :allow : :prune_duplicates}
      new_ids = create_from_select(target_model_handle,field_set_to_copy,graph.select(*field_set_to_copy.cols),create_opts)
      return new_ids if new_ids.empty?

      #clone attribuutes
      #generalize to clone all children
      child_model_name = :attribute #TODO: hardwired
      child_model_handle = source_id_handle.createMH(:model_name => child_model_name, :parent_model_name => model_name)
      child_parent_id_col = child_model_handle.parent_id_field_name()

      child_parent_ds = SQL::ArrayDataset.create(db,new_ids.map{|id|{child_parent_id_col => id}},:parent)

      child_source_wc = {child_parent_id_col => source_id_handle.get_id()}
      field_set_to_copy = FieldSet.all_real(child_model_name).remove_cols(:id,:local_id)
      child_source_fs = FieldSet.opt(field_set_to_copy.remove_cols(child_parent_id_col))
      child_source_ds = get_objects_just_dataset(child_model_handle,child_source_wc,child_source_fs)
      graph = child_parent_ds.graph(:inner,child_source_ds)
      create_opts = {:duplicate_refs => :no_check}
      create_from_select(child_model_handle,field_set_to_copy,graph.select(*field_set_to_copy.cols),create_opts)
    end

    def self.old_clone_post_copy_hook(new_id_handle,target_id_handle,opts={})
      c = new_id_handle[:c]
      
      #create a change pending item associated with component created on the node group adn returns its id (so it can be
      # used as parent to change items for components on all the node groups memebrs
      parent_pending_id = create_pending_change_item(new_id_handle,target_id_handle)
      
      #the component object with its attributes on node group is cloned onto teh node group members; its attribute values must first be changed to null out
      #:value_asserted and set :value_derived 
      component_obj = get_object_deep(new_id_handle)
      #component_obj is of form {ref => {... :attribute => {ref1 => {:value_asserted =>,,}}...}}
      attrs = component_obj.values.first[:attribute].each_value do |attr_assigns|
        attr_assigns[:value_derived] = attr_assigns.delete(:value_asserted)
      end

      child_clone_opts = {:source_obj => component_obj, :parent_pending_change_item_id => parent_pending_id}
      node_group_obj = get_object(target_id_handle)
      #TODO: for efficiency handle by bulk sql operations
      (node_group_obj||{})[:member_id_list].each do |node_id|
        #TODO: need processing that checks if component already on node for components that can only be once on node
        clone(new_id_handle,IDHandle[:c => c,:model_name => :node,:id=> node_id],{},child_clone_opts)
      end
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
