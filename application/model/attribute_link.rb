module XYZ
  class AttributeLink < Model
    set_relation_name(:attribute,:link)

    def self.up()
      foreign_key :input_id, :attribute, FK_CASCADE_OPT
      foreign_key :output_id, :attribute, FK_CASCADE_OPT
      column :function, :json, :default => "eq"
      column :function_index, :json
      #TODO: may deprecate and subsume in function
      column :label, :text, :default => "1"
      has_ancestor_field()
      many_to_one :library, :datacenter, :component, :node, :project
    end

    #######################
    ### object procssing and access functions

    ##########################  add new links ##################

    def self.link_attributes_using_eq(node_group_id_handle,ng_cmp_id_handle,node_cmp_id_handles)
      #TODO: rename params so not specfic to node groups
      #TODO: may convert to computing from search object with links
      node_cmp_mh = node_cmp_id_handles.first.createMH
      node_cmp_wc = {:ancestor_id => ng_cmp_id_handle.get_id()}
      node_cmp_fs = FieldSet.opt([:id],:component)
      node_cmp_ds = get_objects_just_dataset(node_cmp_mh,node_cmp_wc,node_cmp_fs)

      attr_mh = node_cmp_mh.create_childMH(:attribute)

      attr_parent_col = attr_mh.parent_id_field_name()
      node_attr_fs = FieldSet.opt([attr_parent_col,:id,:ref],:attribute)
      node_attr_ds = get_objects_just_dataset(attr_mh,nil,node_attr_fs)

      group_attr_wc = {attr_parent_col => ng_cmp_id_handle.get_id()}
      group_attr_fs = FieldSet.opt([:id,:ref],:attribute)
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
         {:output__id => :output_id},
         {"eq" => :function})
      first_join_ds = i1_ds.join_table(:inner,node_attr_ds,{attr_parent_col => :id},{:table_alias => :output})
      attr_link_ds = first_join_ds.join_table(:inner,group_attr_ds,[:ref],{:table_alias => :input})

      attr_link_fs = FieldSet.new(:attribute,[:ref,attr_link_parent_col,:input_id,:output_id,:function])
      override_attrs = {}
            
      opts = {:duplicate_refs => :no_check,:returning_sql_cols => [:input_id,:output_id]} 
      new_link_info = create_from_select(attr_link_mh,attr_link_fs,attr_link_ds,override_attrs,opts)
      update_type_link_attached(attr_link_mh,:input,new_link_info)
      update_type_link_attached(attr_link_mh,:output,new_link_info)
    end

    def self.add_ipv4_sap_links(new_sap_attr_idh,sap_config_attr_idh,ipv4_host_addrs_idh)
pp [:new_sap_attr_idh,new_sap_attr_idh]
pp [:sap_config_attr_idh,sap_config_attr_idh]
pp [:ipv4_host_addrs_idh,ipv4_host_addrs_idh]
=begin
      return nil if new_attr_sap_idhs.empty?
      attr_mh = cmp_id_handle.createMH(:model_name => :attribute, :parent_model_name => :component)
      create_from_rows(attr_mh,new_sap_attr_rows, :convert => true)
=end

    end

    def self.update_type_link_attached(attr_link_mh,type,new_link_info)
      attr_mh = attr_link_mh.createMH(:model_name => :attribute)
      index = "#{type}_id".to_sym
      field_to_update = "num_attached_#{type}_links".to_sym
      select_wc = SQL.in(:id,new_link_info.map{|r|r[index]})
      select_fs = FieldSet.opt([:id,{SQL::ColRef.sum(field_to_update,1) => field_to_update}],:attribute)
      select_ds = get_objects_just_dataset(attr_mh,select_wc,select_fs)
      update_from_select(attr_mh,FieldSet.new(:attribute,[field_to_update]),select_ds)
    end

    ########################## end add new links ##################

    def self.propagate_when_eq_links(attr_changes)
      return Array.new if attr_changes.empty?
      #build up pattern that traces from root id_handles in changes pending to directly connected links
      # link tracing would look like
      #TODO: rewrite using a search object
      #TODO: below outdated after actual links updated
      # attribute(id_val_pairs).as(a1)([:value_asserted,:action_id])--(input_id)attribute_link(output_id)--attribute.as(a2)([:id]).where(:value_asserted => nil))
      #return a1[:value_asserted.as(:value_derived),:action_id],a2[:id]
#TODO: temp debug  propagate(attr_changes.map{|x|x.id_handle})

      attr_mh = attr_changes.first.id_handle.createMH(:model_name => :attribute)

      id_val_pairs = attr_changes.map{|change| {:id => change.id_handle.get_id(),:value_asserted => change.changed_value, :action_id => change.action_id_handle.get_id()}}
      input_attr_ds = SQL::ArrayDataset.create(db,id_val_pairs,attr_mh,{:convert_for_update => true})

      #first put in relation that traces along attribute link from output matching an idhandle in changes to inputs
      attr_link_mh = attr_changes.first.id_handle.createMH(:model_name => :attribute_link)
      attr_link_wc = nil
      attr_link_fs = FieldSet.opt([:input_id,:output_id],:attribute_link)
      attr_link_ds = get_objects_just_dataset(attr_link_mh,attr_link_wc,attr_link_fs)

      output_attr_mh = attr_link_mh.createMH(:model_name => :attribute)
      #condition is to prune out attributes on output side that have asserted values
      output_attr_wc = {:value_asserted => nil}
      output_attr_fs = FieldSet.opt([:id,:display_name,{:value_derived => :old_val}],:attribute)
      output_attr_ds = get_objects_just_dataset(output_attr_mh,output_attr_wc,output_attr_fs)

      first_join_ds = input_attr_ds.select({:id => :input_id},{:value_asserted => :value_derived},:action_id).from_self.join_table(:inner,attr_link_ds,[:input_id]) 
      attrs_to_change_ds = first_join_ds.join_table(:inner,output_attr_ds,{:id => :output_id})
      returning_cols_opts = {:returning_cols => [:id,:display_name,:action_id,:old_val,{:value_derived => :new_val}]}
      update_ret = update_from_select(output_attr_mh,FieldSet.new(:attribute,[:value_derived]),attrs_to_change_ds,returning_cols_opts)

      attrs_with_base_objects = Attribute.get_attributes_with_base_objects(attr_mh,update_ret.map{|r|r[:id]},:node)
      indexed_attrs_with__base_objects = attrs_with_base_objects.inject({}){|h,row|h.merge(row[:id] => row)}
      #create the new pending changes
      parent_action_mh = attr_changes.first.action_id_handle.createMH()
      new_item_hashes = update_ret.map do |r|
        new_item_hash ={
          :new_item => attr_mh.createIDH(:guid => r[:id], :display_name => r[:display_name]), 
          :parent => parent_action_mh.createIDH(:guid => r[:action_id]),
          :change => {:old => r[:old_val], :new => r[:new_val]}
        }
        base_object = indexed_attrs_with__base_objects[r[:id]]
        new_item_hash.merge(base_object ? {:base_object => base_object} : {})
      end
      Action.create_pending_change_items(new_item_hashes)
    end
    #TODO: below will subsume above
    #if no fn can be computable on sql side (like equal can short cuit by not having to pass through and process through ruby
    def self.propagate(input_attr_id_handles)
      return Array.new if input_attr_id_handles.empty?
      attr_mh = input_attr_id_handles.first
      field_set = Model::FieldSet.new(:attribute,[:id,:value_asserted,:value_derived,:linked_attributes])
      filter = [:and, [:oneof, :attribute__id, input_attr_id_handles.map{|idh|idh.get_id()}]]
      #dont propagate to attributes with asseretd values
      wc = {:attribute2__value_asserted => nil}
      ds = SearchObject.create_from_field_set(field_set,attr_mh[:c],filter).create_dataset().where(wc)
      new_val_rows = ds.all.map do |row|
        {:id => row[:attribute2][:id], 
          :value_derived => compute_new_value(row[:attribute_link][:function],row[:attribute_link][:function_index],row[:attribute_value],row[:attribute2][:value_derived])
        }
      end
      return Array.new if new_val_rows.empty?
      update_select_ds = SQL::ArrayDataset.create(db,new_val_rows,attr_mh) 
      update_from_select(attr_mh,FieldSet.new(:attribute,[:value_derived]),update_select_ds)
    end

    def self.compute_new_value(function,function_index,attribute_value,old_value)
      case function
       when "eq"
        attribute_value 
       else
        raise ErrorNotImplemented.new("AttributeLink.compute_new_value not implemented yet for fn #{function}")
      end
   end

    def self.get_legal_connections(parent_id_handle)
      c = parent_id_handle[:c]
      parent_id = IDInfoTable.get_id_from_id_handle(parent_id_handle)
      component_ds = get_objects_just_dataset(ModelHandle.new(c,:component),nil,{:parent_id => parent_id}.merge(FieldSet.opt([:id,:external_ref],:component)))
      attribute_ds = get_objects_just_dataset(ModelHandle.new(c,:attribute),nil,FieldSet.opt([:id,:external_ref,:component_component_id],:attribute))

      attribute_link_ds = get_objects_just_dataset(ModelHandle.new(c,:attribute_link))
      component_ds.graph(:inner,attribute_ds,{:component_component_id => :id}).graph(:left_outer,attribute_link_ds,{:input_id => :id}).where({:attribute_link__id => nil}).all
    end

    def self.get_legal_connections_wrt_endpoint(attribute_id_handle,parent_id_handle)
    end
   private

    ##### Actions
=begin TODO: needs fixing up or removal
      def create(target_id_handle,input_id_handle,output_id_handle,href_prefix,opts={})
        raise Error.new("Target location (#{target_id_handle}) does not exist") unless exists? target_id_handle

        input_obj = Object.get_object(input_id_handle)
        raise Error.new("Input endpoint does not exist") if input_obj.nil?
        i_ref = input_obj.get_qualified_ref

        output_obj = Object.get_object(output_id_handle)
        raise Error.new("Output endpoint does not exist") if output_obj.nil?
        o_ref = output_obj.get_qualified_ref

        link_content = {:input_id => input_obj[:id],:output_id => output_obj[:id]}
        link_ref = (i_ref.to_s + "_" + o_ref.to_s).to_sym

        factory_id_handle = get_factory_id_handle(target_id_handle,:attribute_link)
        link_ids = create_from_hash(factory_id_handle,{link_ref => link_content})
        fn = ret_function_if_can_determine(input_obj,output_obj)
        output_obj.check_and_set_derived_rel_from_link_fn!(fn)
        link_ids
      end
=end
      #returns function if can determine from semantic type of input and output
      #throws an error if finds a mismatch
    class << self
      def ret_function_if_can_determine(input_obj,output_obj)
        i_sem = input_obj[:semantic_type]
        return nil if i_sem.nil?
        o_sem = output_obj[:semantic_type]
        return nil if o_sem.nil?

        #TBD: haven't put in any rules if they have different seamntic types
        return nil unless i_sem.keys.first == o_sem.keys.first      
      
        sem_type = i_sem.keys.first
        ret_function_endpoints_same_type(i_sem[sem_type],o_sem[sem_type])
      end

    private

      def ret_function_endpoints_same_type(i,o)
        #TBD: more robust is allowing for example output to be "database", which matches with "postgresql" and also to have version info, etc
        raise Error.new("mismatched input and output types") unless i[:type] == o[:type]
        return :equal if !i[:is_array] and !o[:is_array]
        return :equal if i[:is_array] and o[:is_array]
        return :concat if !i[:is_array] and o[:is_array]
        raise Error.new("mismatched input and output types") if i[:is_array] and !o[:is_array]
        nil
      end
    end

    ##instance fns
    def get_input_attribute(opts={})
      return nil if self[:input_id].nil?
      get_object_from_db_id(self[:input_id],:attribute)
    end

    def get_output_attribute(opts={})
      return nil if self[:output_id].nil?
      get_object_from_db_id(self[:output_id],:attribute)
    end
  end
  # END Attribute class definition
end

