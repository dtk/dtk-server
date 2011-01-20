module XYZ
   class AttributeLink < Model
    set_relation_name(:attribute,:link)

    def self.up()
      foreign_key :input_id, :attribute, FK_CASCADE_OPT
      foreign_key :output_id, :attribute, FK_CASCADE_OPT
      column :type, :varchar, :size => 25 # "internal" | "external" | "member"
      column :hidden, :boolean, :default => false
      column :function, :json, :default => "eq"
      column :function_index, :json
      #TODO: may deprecate and subsume in function
      column :label, :text, :default => "1"
      many_to_one :library, :datacenter, :component, :node
    end

    #######################
    ### object processing and access functions

    ##########################  add new links ##################
    def self.create_from_hash(parent_id_handle,hash)
      rows = hash.values.first.values.map do |raw_row|
        row = Aux.col_refs_to_keys(raw_row)
        row[:input_id] = row[:input_id].to_i
        row[:output_id] = row[:output_id].to_i
        row
      end
      create_links(parent_id_handle,rows)
    end

    
    def self.create_links(parent_id_handle,rows)
      attr_link_mh = parent_id_handle.create_childMH(:attribute_link)
      #TODO: parent model name can also be node
      attr_mh = attr_link_mh.createMH(:model_name => :attribute,:parent_model_name=>:component)

      #set the parent id and ref and make 
      parent_col = attr_link_mh.parent_id_field_name()
      parent_id = parent_id_handle.get_id()
      rows.each do |row|
        row[parent_col] ||= parent_id
        row[:ref] = "attribute_link:#{row[:input_id]}-#{row[:output_id]}"
      end

      #TODO: make more efficient by setting attribute_link.function_index and attribute.link_info in fewer sql ops 
      #get info needed to set attribute_link.function_index
      endpoint_ids = rows.map{|r|[r[:input_id],r[:output_id]]}.flatten.uniq
      attr_wc = SQL.in(:id,endpoint_ids)
      attr_fs = FieldSet.opt([:id,:link_info,:value_derived,:value_asserted,:semantic_type],:attribute)
      attr_ds = get_objects_just_dataset(attr_mh,attr_wc,attr_fs)

      attr_info = attr_ds.all.inject({}) do |h,attr|
        new_info = {
          :link_info => Attribute::LinkInfo.new(attr[:link_info]),
          :semantic_type => SemanticType.create_from_attribute(attr)
        }
        h.merge(attr[:id] => attr.merge(new_info))
      end
   pp [:attr_info,attr_info]   

      #set function and new function_index and new updated link_info
      updated_link_info = Hash.new
      rows.each do |row|
        input_id = row[:input_id]
        link_info = attr_info[input_id][:link_info]
        new_index = link_info.set_next_index!()
        row[:function] = SemanticType.find_link_function(attr_info[input_id][:semantic_type],attr_info[row[:output_id]][:semantic_type])
        row[:function_index] = new_index
        updated_link_info[input_id] = link_info.hash_value
      end

      #update attribute link_info
      update_from_rows(attr_mh,updated_link_info.map{|id,link_info|{:id => id, :link_info => link_info}}) 

      #create attribute_links
      select_ds = SQL::ArrayDataset.create(db,rows,attr_link_mh,:convert_for_create => true)
      override_attrs = {}
      field_set = FieldSet.new(attr_link_mh[:model_name],rows.first.keys)
      returning_ids = create_from_select(attr_link_mh,field_set,select_ds,override_attrs,:returning_sql_cols=> [:id])
      propagate_from_create(attr_mh,attr_info,rows)
      returning_ids
    end

     ### special purpose create links ###
    def self.create_links_node_group_members(node_group_id_handle,ng_cmp_id_handle,node_cmp_id_handles)
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
         {"member" => :type},                                 
         {"eq" => :function})
      first_join_ds = i1_ds.join_table(:inner,node_attr_ds,{attr_parent_col => :id},{:table_alias => :input})
      attr_link_ds = first_join_ds.join_table(:inner,group_attr_ds,[:ref],{:table_alias => :output})

      attr_link_fs = FieldSet.new(:attribute,[:ref,attr_link_parent_col,:input_id,:output_id,:function,:type])
      override_attrs = {}
            
      opts = {:duplicate_refs => :no_check,:returning_sql_cols => [:input_id,:output_id]} 
      create_from_select(attr_link_mh,attr_link_fs,attr_link_ds,override_attrs,opts)
    end

    def self.create_links_ipv4_sap(new_sap_attr_idh,sap_config_attr_idh,ipv4_host_addrs_idh,node_idh)
      attr_link_mh = node_idh.createMH(:model_name => :attribute_link, :parent_model_name => :node)
      new_sap_id,sap_config_id,ipv4_id,node_id = [new_sap_attr_idh,sap_config_attr_idh,ipv4_host_addrs_idh,node_idh].map{|x|x.get_id()}
      
      new_link_rows =
        [
         {
           :ref => "sap_config:#{sap_config_id.to_s}-#{new_sap_id}",
           :display_name => "link:sap_config-sap",
           :input_id => new_sap_id,
           :output_id => sap_config_id,
           :type => "internal",
           :hidden => true,
           :function => "sap_config_ipv4",
           :node_node_id => node_id
         },
         {
           :ref => "host_address:#{ipv4_id.to_s}-#{new_sap_id}",
           :display_name => "link:host_address-sap",
           :input_id => new_sap_id,
           :output_id => ipv4_id,
           :type => "internal",
           :hidden => true,
           :function => "host_address_ipv4",
           :node_node_id => node_id
         }
        ]
      create_from_rows(attr_link_mh,new_link_rows)
    end

     ### aux fn for creaet links ###
    def self.propagate_from_create(attr_mh,attr_info,attr_link_rows)
      new_val_rows = attr_link_rows.map do |attr_link_row|
        input_attr = attr_info[attr_link_row[:input_id]]
        output_attr = attr_info[attr_link_row[:output_id]]
        propagate_proc = PropagateProcessor.new(attr_link_row,input_attr,output_attr)
        propagate_proc.propagate().merge(:id => input_attr[:id])
      end
      return Array.new if new_val_rows.empty?
      update_select_ds = SQL::ArrayDataset.create(db,new_val_rows,attr_mh) 
      update_from_select(attr_mh,FieldSet.new(:attribute,[:value_derived,:link_info]),update_select_ds)
    end


    ########################## end add new links ##################

    ########################## propagate changes ##################
    #returns all changes
    #TODO: flat list now; look at nested list reflecting hierarchical plan decomposition
    def self.propagate(output_attr_id_handles)
      return Hash.new if output_attr_id_handles.empty?
      attr_mh = output_attr_id_handles.first
      field_set = Model::FieldSet.new(:attribute,[:id,:value_asserted,:value_derived,:semantic_type,:linked_attributes])
      filter = [:and, [:oneof, :attribute__id, output_attr_id_handles.map{|idh|idh.get_id()}]]
      #dont propagate to attributes with asserted values
      wc = {:attribute2__value_asserted => nil}
      ds = SearchObject.create_from_field_set(field_set,attr_mh[:c],filter).create_dataset().where(wc)
      change_info = Hash.new
      new_val_rows = Array.new
      ds.all.each do |row|
        input_attr_row = row[:attribute2]
        output_attr_row = row
        propagate_proc = PropagateProcessor.new(row[:attribute_link],input_attr_row,output_attr_row)

        new_value_row = propagate_proc.propagate().merge(:id => input_attr_row[:id])
        new_val_rows << new_value_row

        change_info[input_attr_row[:id]] = {
          :new_item => attr_mh.createIDH(:guid => input_attr_row[:id], :display_name => input_attr_row[:display_name]),
          :change => {:old => input_attr_row[:value_derived], :new => new_value_row[:value_derived]}
        }
      end
      return Hash.new if new_val_rows.empty?
      changed_ids = Attribute.update_changed_values(attr_mh,new_val_rows,:value_derived)
      #if no changes exit, otherwise recursively call propagate
      return Hash.new if changed_ids.empty?

      pruned_changes = change_info.inject({}){|h,kv|h.merge(kv[0] => kv[1]) if changed_ids.map{|x|x[:id]}.include?(kv[0])}||{}

      propagated_changes = propagate(changed_ids.map{|r|attr_mh.createIDH(:guid => r[:id])}) #TODO: see if setting parent right?
      pruned_changes.merge(propagated_changes)
    end

=begin
  TODO: need to modify fragment I cut and paste below from deprecated fn:  propagate_when_eq_links
  TODO: need tpo figure out what changes are recorded
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
=end



   ########################## end: propagate changes ##################

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

