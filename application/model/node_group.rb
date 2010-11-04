module XYZ
  class NodeGroup < Model
    set_relation_name(:node,:node_group)
    def self.up()
      #TODO: should it instaed be pointer to by pointer search_object
      column :dynamic_search_pattern, :json #sql where clause that picks out node members and means to ignore memebrship assocs
      virtual_column :member_id_list
      virtual_column :member_list
      many_to_one :library, :datacenter, :project
      one_to_many :component
    end

    ### virtual column defs
    def member_list()
      self[:node]||[]
    end
    def member_id_list()
      member_list.map{|n|n[:id]}
    end
    #######################
    ### object procssing and access functions
    def self.clone_post_copy_hook(new_id_handle,target_id_handle,opts={})

      #create a change pending item associated with component created on the node group adn returns its id (so it can be
      # used as parent to change items for components on all the node groups memebrs
      #get_top_container_id_handle(:datacenter) will return nil if top is not a datacenter which wil in turn make PendingChangeItem
      #a no-op; this is desired only having pending objects in datacenter, not library
      action_parent_idh = target_id_handle.get_top_container_id_handle(:datacenter)
      target_display_name = target_id_handle[:display_name]|| get_display_name(target_id_handle)
      new_item_hash = {
        :new_item => new_id_handle,
        :parent => action_parent_idh,
        :base_object => {:node_group => {:display_name => target_display_name}}
      }
      action_id_handle = Action.create_pending_change_item(new_item_hash)
      case new_id_handle[:model_name]
       when :component
        clone_post_copy_hook_component(new_id_handle,target_id_handle,action_id_handle,opts)
       else
        raise Error.new("clone_post_copy_hook to node_group from #{new_id_handle[:model_name]} not implemented yet")
      end
    end

    def self.get_wspace_display(id_handle)
      node_group_id = IDInfoTable.get_id_from_id_handle(id_handle)
      node_group_mh = id_handle.createMH(:model_name => :node_group)
      get_objects(node_group_mh,{:id => node_group_id}).first
    end

    #needed to overwrite this fn because special processing to handle :dynamic_search_pattern
    def self.get_objects(model_handle,where_clause={},opts={})
      #break into two parts; one with explicit links and the other with :dynamic_search_pattern non null
      static = get_objects_static(model_handle,where_clause,opts)
      dynamic = get_objects_dynamic(model_handle,where_clause,opts)
      static + dynamic
    end
   private

    def self.clone_post_copy_hook_component(ng_cmp_id_handle,node_group_id_handle,action_id_handle,opts={})
      node_group_obj = get_object(node_group_id_handle)
      member_list = (node_group_obj||{})[:member_list]||[]
      targets = member_list.map{|node|node_group_id_handle.createIDH({:model_name => :node,:id=> node[:id], :display_name => node[:display_name]})}
      return Array.new if  targets.empty?
      recursive_override_attrs={
        :attribute => {
          :value_derived => :value_asserted,
          :value_asserted => nil
        }
      }
      node_cmp_id_handles = clone_copy(ng_cmp_id_handle,targets,recursive_override_attrs)
      return node_cmp_id_handles if node_cmp_id_handles.empty?

      #create pending_change items for all the components created on the nodes; the
      #pending change item generated for the node group component is their parents
      new_items = node_cmp_id_handles.map do |idh|
        new_item = {:new_item => idh, :parent => action_id_handle}
        #TODO: make below call to  idh.get_parent_id()
        object_idh = targets.find{|o|o.get_id() == idh[:parent_guid]}
        if (object_idh||{})[:display_name]
          new_item.merge!(:base_object => {:node => {:display_name => object_idh[:display_name]}})
        end
        new_item
      end
      Action.create_pending_change_items(new_items)

      #put in attribute links, linking attributes attached to component ng_cmp_id_handle
      #TODO: may convert to computing from search object with links
      node_cmp_mh = node_cmp_id_handles.first.createMH
      node_cmp_wc = {:ancestor_id => ng_cmp_id_handle.get_id()}
      node_cmp_fs = FieldSet.opt([:id])
      node_cmp_ds = get_objects_just_dataset(node_cmp_mh,node_cmp_wc,node_cmp_fs)

      attr_mh = node_cmp_mh.create_childMH(:attribute)

      attr_parent_col = attr_mh.parent_id_field_name()
      node_attr_fs = FieldSet.opt([attr_parent_col,:id,:ref])
      node_attr_ds = get_objects_just_dataset(attr_mh,nil,node_attr_fs)

      group_attr_wc = {attr_parent_col => ng_cmp_id_handle.get_id()}
      group_attr_fs = FieldSet.opt([:id,:ref])
      group_attr_ds = get_objects_just_dataset(attr_mh,group_attr_wc,group_attr_fs)

      #attribute link has same parent as node_group
      attr_link_mh = node_group_id_handle.create_peerMH(:attribute_link)
      attr_link_parent_id_handle = node_group_id_handle.get_parent_id_handle()
      attr_link_parent_col = attr_link_mh.parent_id_field_name()
      ref_prefix = "attribute_link:"
      i1_ds = node_cmp_ds.select(
         {SQL::ColRef.concat(ref_prefix,:input__id.cast(:text),"-",:output__id.cast(:text)) => :ref},
         {attr_link_parent_id_handle.get_id() => attr_link_parent_col},
         {:input__id => :input_id},
         {:output__id => :output_id})
      first_join_ds = i1_ds.join_table(:inner,node_attr_ds,{attr_parent_col => :id},{:table_alias => :output})
      attr_link_ds = first_join_ds.join_table(:inner,group_attr_ds,[:ref],{:table_alias => :input})

      attr_link_fs = FieldSet.new([:ref,attr_link_parent_col,:input_id,:output_id])
      override_attrs = {}
      create_from_select(attr_link_mh,attr_link_fs,attr_link_ds,override_attrs,{:duplicate_refs => :no_check})
      #TODO: links for monitor_items

    end
    #######################

   private
    #TODO: have this bring in same fields as dynamic
    def self.get_objects_static(model_handle,where_clause={},opts={})
      c = model_handle[:c]
      #important that Model.get_objects called, not get_objects
      #below returns just scalar attributes
      ng = Model.get_objects(model_handle,SQL.and(where_clause,{:dynamic_search_pattern => nil}),opts)
      return ng if ng.empty?
      #TODO: encapsulate this pattern to nest multiple matches; might have a variant of join_table that does this
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
      #TODO: so if can make more efficient
      #important that Model.get_objects called, not get_objects
      groups_info = Model.get_objects(model_handle,SQL.and(where_clause,SQL.and(where_clause,SQL.not(:dynamic_search_pattern => nil))),
                                opts.merge(FieldSet.opt([:id,:display_name,:dynamic_search_pattern])))

#      groups_info.map{|group|group.merge :node => Model.get_objects(ModelHandle.new(c,:node),group[:dynamic_search_pattern])}
      groups_info.map do |group|
        search_pattern =  group[:dynamic_search_pattern].merge(:columns => [:id,:display_name])
        search_object = SearchObject.create_from_input_hash({"search_pattern" => search_pattern},:node_group,model_handle[:c])
        group.merge :node => get_objects_from_search_object(search_object)
      end
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
