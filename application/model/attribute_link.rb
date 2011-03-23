module XYZ
  class AttributeLink < Model
    set_relation_name(:attribute,:link)

    def self.up()
      foreign_key :input_id, :attribute, FK_CASCADE_OPT
      foreign_key :output_id, :attribute, FK_CASCADE_OPT
      column :type, :varchar, :size => 25, :default => "external" # "internal" | "external" | "member"
      column :hidden, :boolean, :default => false
      column :function, :json, :default => "eq"
      column :function_index, :json
      foreign_key :assembly_id, :component, FK_SET_NULL_OPT #TODO: may instead just determine by seeing attributes contained and what is linked
      #TODO: may deprecate and subsume in function
      column :label, :text, :default => "1"
      many_to_one :library, :datacenter, :component, :node
    end


    ##########################  add new links ##################
    def self.create_port_and_attr_links(parent_idh,rows,opts={})
      attr_link_mh = parent_idh.create_childMH(:attribute_link)
      #TODO: parent model name can also be node
      attr_mh = attr_link_mh.createMH(:model_name => :attribute,:parent_model_name=>:component)

      #set the parent id and ref and make 
      parent_col = attr_link_mh.parent_id_field_name()
      parent_id = parent_idh.get_id()
      rows.each do |row|
        row[parent_col] ||= parent_id
        row[:ref] = "attribute_link:#{row[:input_id]}-#{row[:output_id]}"
      end

      #TODO: make more efficient by setting attribute_link.function_index and attribute.link_info in fewer sql ops 
      #get info needed to set attribute_link.function_index
      endpoint_ids = rows.map{|r|[r[:input_id],r[:output_id]]}.flatten.uniq
      sp_hash = {
        :columns => [:id,:link_info,:attribute_value,:semantic_type_object,:component_parent],
        :filter => [:and, [:oneof, :id, endpoint_ids]]
      }
      attr_rows = get_objects_from_sp_hash(attr_mh,sp_hash)
      attr_info = attr_rows.inject({}){|h,attr|h.merge(attr[:id] => attr)}


      #set function and new function_index and new updated link_info
      updated_link_info = Array.new
      rows.each do |row|
        input_id = row[:input_id]
        new_index = Attribute::LinkInfo.set_next_index!(attr_info[input_id])
        row[:function] = SemanticType.find_link_function(attr_info[input_id][:semantic_type_object],attr_info[row[:output_id]][:semantic_type_object])
        row[:function_index] = new_index
        updated_link_info << {:id => input_id,:link_info => attr_info[input_id][:link_info]}
      end

      #update attribute link_info
      update_from_rows(attr_mh,updated_link_info)

      #create attribute_links
      select_ds = SQL::ArrayDataset.create(db,rows,attr_link_mh,:convert_for_create => true)
      override_attrs = {}
      field_set = FieldSet.new(attr_link_mh[:model_name],rows.first.keys)
      returning_ids = create_from_select(attr_link_mh,field_set,select_ds,override_attrs,:returning_sql_cols=> [:id])
      propagate_from_create(attr_mh,attr_info,rows)

      return returning_ids if opts[:no_nested_processing]
      attr_links = rows.map{|r|{:input => attr_info[r[:input_id]],:output => attr_info[r[:output_id]]}}

      create_related_links?(parent_idh,attr_links)
      #TODO: assumption is that what is created by create_related_links? has no bearing on l4 ports (as manifsted by using attr_links arg computred before create_related_links? call
      Port.create_and_update_l4_ports_and_links?(parent_idh,attr_links)
    end

    def self.create_related_links?(parent_idh,attr_links)
      attr_links.each{|link_info|create_related_link?(parent_idh,link_info)}
    end

    #TODO: can we make this more data driven 
    def self.create_related_link?(parent_idh,link_info)
      input_cmp = link_info[:input][:component_parent]
      if ComponentType::Application.include?(input_cmp)
        attr_db_config = input_cmp.get_virtual_attribute("db_config",[:id],:semantic_type_summary)
        create_related_link_from_db_config(parent_idh,link_info,attr_db_config) if attr_db_config
      end
    end

    def self.create_related_link_from_db_config(parent_idh,link_info,attr_db_config)
      db_server_component = link_info[:output][:component_parent]
      db_server_node = parent_idh.createIDH(:id => db_server_component[:node_node_id],:model_name => :node).create_object()
      db_component_idh = ComponentType::Database.clone_db_onto_db_server_node(db_server_node,db_server_component)

      #find link between db component 
      attr_db_params = db_component_idh.create_object().get_virtual_attribute("db_params",[:id],:semantic_type_summary)
      unless attr_db_params
        Log.error("cannot find db_params attribute on db_component")
        return
      end
      link = {:input_id => attr_db_params[:id],:output_id => attr_db_config[:id]}
      opts = {:no_nested_processing => true}
      create_port_and_attr_links(parent_idh,[link],opts)
    end


####################


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


    def self.create_links_sap(link_info,sap_attr_idh,sap_config_attr_idh,par_idh,node_idh)
      attr_link_mh = sap_attr_idh.createMH(:model_name => :attribute_link, :parent_model_name => :node)
      sap_id,sap_config_id,par_id,node_id = [sap_attr_idh,sap_config_attr_idh,par_idh,node_idh].map{|x|x.get_id()}

      sap_config_name = link_info[:sap_config]
      sap_name = link_info[:sap]
      parent_attr_name = link_info[:parent_attr_name]

      new_link_rows =
        [
         {
           :ref => "#{sap_config_name}:#{sap_config_id.to_s}-#{sap_id}",
           :display_name => "link:#{sap_config_name}-#{sap_name}",
           :input_id => sap_id,
           :output_id => sap_config_id,
           :type => "internal",
           :hidden => true,
           :function => link_info[:sap_config_fn_name],
           :node_node_id => node_id
         },
         {
           :ref => "#{parent_attr_name}:#{par_id.to_s}-#{sap_id}",
           :display_name => "link:#{parent_attr_name}-#{sap_name}",
           :input_id => sap_id,
           :output_id => par_id,
           :type => "internal",
           :hidden => true,
           :function => link_info[:parent_fn_name],
           :node_node_id => node_id
         }
        ]
      create_from_rows(attr_link_mh,new_link_rows)
    end

    #TODO: deprecate below after subsuming from above
    def self.create_links_l4_sap(new_sap_attr_idh,sap_config_attr_idh,ipv4_host_addrs_idh,node_idh)
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
           :function => "sap_config__l4",
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

     ### aux fn for create links ###
    def self.propagate_from_create(attr_mh,attr_info,attr_link_rows)
      new_val_rows = attr_link_rows.map do |attr_link_row|
        input_attr = attr_info[attr_link_row[:input_id]]
        output_attr = attr_info[attr_link_row[:output_id]]
        propagate_proc = PropagateProcessor.new(attr_link_row,input_attr,output_attr)
        propagate_proc.propagate().merge(:id => input_attr[:id])
      end
      return Array.new if new_val_rows.empty?
      update_select_ds = SQL::ArrayDataset.create(db,new_val_rows,attr_mh,:convert_for_update => true) 
      update_from_select(attr_mh,FieldSet.new(:attribute,[:value_derived,:link_info]),update_select_ds)
    end


    ########################## end add new links ##################

    ########################## propagate changes ##################
    #returns all changes
    #TODO: flat list now; look at nested list reflecting hierarchical plan decomposition
    def self.propagate(output_attr_id_handles,parent_id_handles=nil)
      return Hash.new if output_attr_id_handles.empty?
      attr_mh = output_attr_id_handles.first.createMH()
      output_attr_ids = output_attr_id_handles.map{|idh|idh.get_id()}
      sp_hash = {
        :relation => :attribute,
        :filter => [:and,[:oneof, :id, output_attr_ids]],
        :columns => [:id,:value_asserted,:value_derived,:semantic_type,:linked_attributes]
      }
      attrs_to_update = Model.get_objects_from_sp_hash(attr_mh,sp_hash)
    
      #dont propagate to attributes with asserted values TODO: push this restriction into search pattern
      attrs_to_update.reject!{|r|(r[:attribute2]||{})[:value_asserted]}
      change_info = Hash.new
      new_val_rows = Array.new

      
      parent_map = Hash.new
      if parent_id_handles
        output_attr_ids.each_with_index{|id,i|parent_map[id] = parent_id_handles[i]}
      end

      attrs_to_update.each_with_index do |row,i|
        input_attr_row = row[:attribute2]
        output_attr_row = row
        propagate_proc = PropagateProcessor.new(row[:attribute_link],input_attr_row,output_attr_row)

        new_value_row = propagate_proc.propagate().merge(:id => input_attr_row[:id])

        #case on whether the input attribute is also upstream in attrs_to_update; if so just update these upstream
        #references; otehrwise addpend to new_val_rows and change_info
        attr_upstream = false
        (i+1..attrs_to_update.size-1).each do |j|
          if input_attr_row[:id] == attrs_to_update[j][:attribute2][:id]
            attr_upstream = true
            attrs_to_update[j][:attribute2][:value_derived] = new_value_row[:value_derived]
          end
        end
        unless attr_upstream
          new_val_rows << new_value_row

          change = {
            :new_item => attr_mh.createIDH(:guid => input_attr_row[:id], :display_name => input_attr_row[:display_name]),
            :change => {:old => input_attr_row[:value_derived], :new => new_value_row[:value_derived]}
          }
          change.merge!(:parent => parent_map[row[:id]]) if parent_map[row[:id]]
          change_info[input_attr_row[:id]] = change
        end
      end

      return Hash.new if new_val_rows.empty?
      changed_ids = Attribute.update_changed_values(attr_mh,new_val_rows,:value_derived)
      #if no changes exit, otherwise recursively call propagate
      return Hash.new if changed_ids.empty?

      #TODO: using flat structure wrt to parents; so if parents pushed down use parents associated with trigger for change
      pruned_changes = Hash.new
      nested_parent_idhs = nil
      nested_idhs = Array.new
      changed_ids.each do |r|
        id = r[:id]
        pruned_changes[id] = change_info[id]
        nested_idhs << attr_mh.createIDH(:id => id)
        if parent_idh = change_info[id][:parent]
          nested_parent_idhs ||= Array.new
          nested_parent_idhs << parent_idh
        end
      end
      
      propagated_changes = propagate(nested_idhs,nested_parent_idhs)
      pruned_changes.merge(propagated_changes)
    end

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

