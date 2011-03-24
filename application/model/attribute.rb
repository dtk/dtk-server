module XYZ
  class Attribute < Model
    set_relation_name(:attribute,:attribute)
    def self.up()
      external_ref_column_defs()

      #columns related to the value
      column :value_asserted, :json, :ret_keys_as_symbols => false
      column :value_derived, :json, :ret_keys_as_symbols => false
      column :value_actual, :json, :ret_keys_as_symbols => false
      #TODO: may rename attribute_value to desired_value
      virtual_column :attribute_value, :type => :json, :local_dependencies => [:value_asserted,:value_derived],
        :sql_fn => SQL::ColRef.coalesce(:value_asserted,:value_derived)

      #columns related to the data/semantic type
      column :data_type, :varchar, :size => 25
      column :semantic_type, :json #points to structural info for a json var 
      column :semantic_type_summary, :varchar, :size => 25 #for efficiency optional token that summarizes info from semantic_type
      virtual_column :semantic_type_object, :type => :object, :hidden => true, :local_dependencies => [:semantic_type]

      ###cols that relate to who or what can or does change the attribute
      #TODO: need to clearly relate these four
      column :read_only, :boolean, :default => false 
      column :dynamic, :boolean, :default => false #means dynamically set by an executable action
      virtual_column :port_type, :type => :varchar, :hidden => true, :local_dependencies => [:is_port,:semantic_type_summary]
      column :cannot_change, :boolean, :default => false


      column :required, :boolean, :default => false #whether required for this attribute to have a value inorder to execute actions for parent component; TODO: may be indexed by action
      column :hidden, :boolean, :default => false

      #columns related to links
      column :is_port, :boolean, :default => false
      virtual_column :port_is_external, :type => :boolean, :hidden => true, :local_dependencies => [:is_port,:semantic_type_summary]


      virtual_column :has_port_object, :type => :booelan, :hidden => true, :local_dependencies => [:is_port,:semantic_type_summary]

      column :link_info, :json, :ret_keys_as_symbols => false

      virtual_column :is_unset, :type => :boolean, :hidden => true, :local_dependencies => [:value_asserted,:value_derived,:data_type,:semantic_type]

      virtual_column :parent_name, :possible_parents => [:component,:node]
      many_to_one :component, :node
      one_to_many :dependency #for ports indicating what they can connect to

      virtual_column :dependencies, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :dependency,
           :alias => :dependencies,
           :convert => true,
           :join_type => :inner,
           :join_cond=>{:attribute_attribute_id => q(:attribute,:id)},
           :cols => [:id,:search_pattern,:type,:description,:severity]
         }]

      virtual_column :component_parent, :type => :json, :hidden => true,
        :remote_dependencies =>
        [
         {
           :model_name => :component,
           :alias => :component_parent,
           :convert => true,
           :join_type => :left_outer,
           :join_cond=>{:id => p(:attribute,:component)},
           :cols => [:id,:display_name,:component_type,:most_specific_type,:ancestor_id,:node_node_id]
         }]

      virtual_column :port_info, :type => :boolean, :hidden => true,
      :remote_dependencies => 
        [
         {
           :model_name => :port,
           :alias => :port_external,
           :join_type => :inner,
           :filter => [:eq,:type,"external"],
           :join_cond=>{:external_attribute_id => q(:attribute,:id)},
           :cols => [:id,:type,id(:node),:containing_port_id,:external_attribute_id,:ref]
         },
         {
           :model_name => :port,
           :alias => :port_l4,
           :join_type => :left_outer,
           :filter => [:eq,:type,"l4"],
           :join_cond=>{:id => q(:port_external,:containing_port_id)},
           :cols => [:id,:type,id(:node),:containing_port_id,:external_attribute_id,:ref]
         }]

      virtual_column :needs_to_be_set, :type => :boolean, :hidden => true, 
        :local_dependencies => [:value_asserted,:value_derived,:read_only,:required],
        :sql_fn => SQL.and({:attribute__value_asserted => nil},{:attribute__value_derived => nil},
                           SQL.not(:attribute__read_only),
                           :attribute__required)

      uri_remote_dependencies = 
        {:uri =>
        [
         {
           :model_name => :id_info,
           :join_cond=>{:relation_id => :attribute__id},
           :cols=>[:relation_id,:uri]
         }
        ]
      }
      virtual_column :id_info_uri, :hidden => true, :remote_dependencies => uri_remote_dependencies

      virtual_column :unraveled_attribute_id, :type => :varchar, :hidden => true #TODO put in depenedncies

      #TODO: may deprecate
      virtual_column :qualified_attribute_name_under_node, :type => :varchar, :hidden => true #TODO put in depenedncies
      virtual_column :qualified_attribute_id_under_node, :type => :varchar, :hidden => true #TODO put in depenedncies
      virtual_column :qualified_attribute_name, :type => :varchar, :hidden => true #not giving dependences because assuming right base_object included in col list

      #base_objects
      virtual_column :base_object_node, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:id=> :attribute__component_component_id},
           :cols=>[:id, :display_name,:node_node_id]
         },
         {
           :model_name => :node,
           :join_type => :inner,
           :join_cond=>{:id=> :component__node_node_id},
           :cols=>[:id, :display_name, {:id => :param_node_id}]
         }
        ]
      virtual_column :base_object_node_datacenter, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:id=> :attribute__component_component_id},
           :cols=>[:id, :display_name,:node_node_id]
         },
         {
           :model_name => :node,
           :join_type => :inner,
           :join_cond=>{:id=> :component__node_node_id},
           :cols=>[:id, :display_name, :datacenter_datacenter_id]
         },
         {
           :model_name => :datacenter,
           :join_type => :inner,
           :join_cond=>{:id=> :node__datacenter_datacenter_id},
           :cols=>[:id, :display_name, {:id => :param_datacenter_id}]
         }
        ]
      virtual_column :base_object_node_feature, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:id=> :attribute__component_component_id},
           :cols=>[:id, :display_name,:component_id]
         },
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:id=> :component__component_id},
           :cols=>[:id, :display_name,:node_node_id]
         },
         {
           :model_name => :node,
           :join_type => :inner,
           :join_cond=>{:id=> :component2__node_node_id},
           :cols=>[:id, :display_name, {:id => :param_node_id}]
         }
        ]
      virtual_column :base_object_node_group, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:id=> :attribute__component_component_id},
           :cols=>[:id, :display_name,:node_node_group_id]
         },
         {
           :model_name => :node_group,
           :join_type => :inner,
           :join_cond=>{:id=> :component__node_node_group_id},
           :cols=>[:id, :display_name, {:id => :param_node_group_id}]
         }
        ]

      virtual_column :base_object_datacenter, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:id=> :attribute__component_component_id},
           :cols=>[:id, :display_name,:node_node_id,:node_node_group_id]
         },
         {
           :model_name => :node,
           :join_cond=>{:id=> :component__node_node_id},
           :cols=>[:id, :display_name, {:datacenter_datacenter_id => :param_node_datacenter_id}]
         },
         {
           :model_name => :node_group,
           :join_cond=>{:id=> :component__node_node_group_id},
           :cols=>[:id, :display_name, {:datacenter_datacenter_id => :param_node_group_datacenter_id}]
         }
        ]


      virtual_column :linked_attributes, :type => :json, :hidden => true, 
        :remote_dependencies => 
        [
         {
           :model_name => :attribute_link,
           :join_type => :inner,
           :join_cond=>{:output_id=> :attribute__id},
           :cols=>[:output_id,:input_id,:function,:function_index]
         },
         {
           :model_name => :attribute,
           :join_type => :inner,
           :join_cond=>{:id=> :attribute_link__input_id},
           :cols=>[:id, :value_asserted,:value_derived,:semantic_type,:link_info,:display_name]
         }
        ]


    end

    ### virtual column defs

    #TODO: collapse this and 4 fields used here
    def is_readonly?()
      (self[:port_type] == "input") or self[:read_only] or self[:dynamic] or self[:cannot_change] 
    end

    def attribute_value()
      self[:value_asserted] || self[:value_derived]
    end

    def semantic_type_object()
      SemanticType.create_from_attribute(self)
    end

    def needs_to_be_set()
      attribute_value().nil? and self[:required] and not self[:read_only]
    end

    def port_is_external()
      return nil unless self[:is_port]
      return nil unless self[:semantic_type_summary]
      (AttributeSemantic::Info[self[:semantic_type_summary]]||{})[:external]
    end
    def port_type()
      return nil unless self[:is_port]
      return nil unless self[:semantic_type_summary]
      (AttributeSemantic::Info[self[:semantic_type_summary]]||{})[:port_type]
    end
    def has_port_object()
      return nil unless self[:is_port]
      return nil unless self[:semantic_type_summary]
      (AttributeSemantic::Info[self[:semantic_type_summary]]||{})[:has_port_object]
    end

    def is_unset()
      #care must be takedn so this is three-valued
      return true if attribute_value().nil?
      return false unless self[:data_type] == "json"
      return nil unless self[:semantic_type]
      has_req_fields = AttributeComplexType.has_required_fields_given_semantic_type?(attribute_value(),self[:semantic_type])
      return nil if has_req_fields.nil?
      has_req_fields ? false : true
    end

    def unraveled_attribute_id()
      qualified_attribute_id_aux()
    end

    #TODO: may deprecate below
    def qualified_attribute_name_under_node()
      qualified_attribute_name_aux()
    end
    def qualified_attribute_id_under_node()
      qualified_attribute_id_aux()
    end
    def qualified_attribute_name()
      node_or_group_name =
        if self.has_key?(:node) then self[:node][:display_name]
        elsif self.has_key?(:node_group) then self[:node_group][:display_name]
      end
      qualified_attribute_name_aux(node_or_group_name)
    end

    def base_object()
      ret = Hash.new
      [:node_group,:node,:component].each{|col|ret[col] = self[col] if self[col]}
      ret
    end

    def id_info_uri()
      (self[:id_info]||{})[:uri]
    end

    #######################
    ######### Model apis

    def get_constraints()
      dependency_list = get_objects_col_from_sp_hash({:columns => [:dependencies]},:dependencies)
      Constraints.new(:or,dependency_list.map{|dep|Constraint.create(dep)})
    end
    
    def self.get_port_info(id_handles)
      get_objects_in_set_from_sp_hash(id_handles,{:cols => [:port_info]},{:keep_ref_cols => true})
    end


    ### object procssing and access functions
    def qualified_attribute_name_aux(node_or_group_name=nil)
      cmp_name = self.has_key?(:component) ? self[:component][:display_name] : nil
      #strip what will be recipe name
      cmp_el = cmp_name ? cmp_name.gsub(/::.+$/,"") : nil
      attr_name = self[:display_name]
      token_array = ([node_or_group_name,cmp_el] + Aux.tokenize_bracket_name(attr_name)).compact
      AttributeComplexType.serialze(token_array)
    end
    def qualified_attribute_id_aux(node_or_group_id_formatted=nil)
      cmp_id = self.has_key?(:component) ? self[:component][:id] : nil
      cmp_id_formatted = AttributeComplexType.container_id(:component,cmp_id)
      attr_id_formatted = AttributeComplexType.container_id(:attribute,self[:id])
      item_path = AttributeComplexType.item_path_token_array(self)||[]
      token_array = ([node_or_group_id_formatted,cmp_id_formatted,attr_id_formatted] + item_path).compact
      AttributeComplexType.serialze(token_array)
    end


    #TODO: want to rename to indicate this is propgate while logging state changes; or have a flag to control whether state changes are logged
    def self.update_and_propagate_attributes(attr_mh,attribute_rows)
      return Array.new if attribute_rows.empty?
      #TODO: was unable to use :update_only_if_change flag on update_from_select because was unable to get old value returning col 
      unpruned_update_select_ds = SQL::ArrayDataset.create(db,attribute_rows,attr_mh,:convert_for_update => true)

      attr_ds = get_objects_just_dataset(attr_mh,nil,FieldSet.opt([{:id => :id2},{:value_asserted => :old_value_asserted}],:attribute))
      #add qualification so that only updated values are set
      join_cond = SQL.and({:id => :id2},SQL.not_equal(:value_asserted,:old_value_asserted))
                          
      update_select_ds =  unpruned_update_select_ds.join_table(:inner,attr_ds,join_cond)

      returning_cols_opts = {:returning_cols => [:id,:value_asserted,:old_value_asserted]}
      changed_attrs_info = update_from_select(attr_mh,FieldSet.new(:attribute,[:value_asserted]),update_select_ds,returning_cols_opts)
      return nil if changed_attrs_info.empty?

      #use sample attribute to find containing datacenter
      sample_attr_idh = attr_mh.createIDH(:id => changed_attrs_info.first[:id])
      #TODO: anymore efficieny way do do this; can pass datacenter in fn
      parent_idh = sample_attr_idh.get_top_container_id_handle(:datacenter)


      #TODO: should we make json conversion more base fn
      changes = changed_attrs_info.map do |r|
        {
          :new_item => attr_mh.createIDH(:id => r[:id]),
          :parent => parent_idh,
          :change => {
            :old => json_form(r[:old_value_asserted]),
            :new => json_form(r[:value_asserted])
          }
        }
      end
      change_idhs = StateChange.create_pending_change_items(changes)
      changes_to_propagate = Array.new
      change_idhs.each_with_index do |change_idh,i|
        change = changes[i]
        changes_to_propagate << AttributeChange.new(change[:new_item],change[:change][:new],change_idh)
      end
      nested_changes = propagate_changes(changes_to_propagate)
      StateChange.create_pending_change_items(nested_changes.values)
    end
   private
   def self.json_form(x)
     begin
       JSON.parse(x)
      rescue Exception
       x
     end
   end

   public

   #TODO: probably deprecate and if notr convert old new values to hash form
    def self.update_and_propagate_attribute_value(attr_idh,value_asserted)
      base_object = get_attribute_with_base_object(attr_idh,attr_idh[:parent_model_name])
      old_value = (base_object||{})[:value_asserted]

      new_val_rows = [{:id => attr_idh.get_id(),:value_asserted => value_asserted}]

      opts = {:update_only_if_change => [:value_asserted],:returning_cols => [:id]}
      changed_ids = update_attribute_values(attr_idh.createMH(),new_val_rows,:value_asserted,opts)
      #if no change, exit 
      return nil if changed_ids.empty?

      #TODO any more efficient way to get action_parent_idh and parent_idh info
      action_parent_idh = attr_idh.get_top_container_id_handle(:datacenter)
      return nil unless action_parent_idh #this would happend if top container is not a datacenter TODO: see if this should be "trapped" at higher level
      new_item_hash = {
        :new_item => attr_idh,
        :parent => action_parent_idh,
        :change => {:old => old_value, :new => value_asserted}
      }
      new_item_hash.merge!(:base_object => base_object) if base_object
      action_idh = StateChange.create_pending_change_item(new_item_hash)

      nested_changes_hash = propagate_changes([AttributeChange.new(attr_idh,value_asserted,action_idh)]) if action_idh

      #compute and merge in base object values and action parernt
      nested_base_objects = get_attributes_with_base_objects(attr_idh.createMH(),nested_changes_hash.keys,:node) #TODO: hard coded :node
      nested_base_objects.each do |base_obj|
        id = base_obj[:id]
        #TODO: need to see if this is right
        if nested_changes_hash[id] 
          nested_changes_hash[id].merge!({:base_object => base_obj,:parent => action_idh})
        end
      end
      pp [:nested_changes,nested_changes_hash.values]
      StateChange.create_pending_change_items(nested_changes_hash.values)
      nil
    end

    def self.update_attribute_values(attr_mh,new_val_rows,cols_x,opts={})
      cols = Array(cols_x)
      return update_attribute_values_incremental(attr_mh,new_val_rows,cols,opts) if new_val_rows.first and new_val_rows.first.kind_of?(PropagateProcessor::OutputArraySlice) 
      update_select_ds = SQL::ArrayDataset.create(db,new_val_rows,attr_mh,:convert_for_update => true)
      update_from_select(attr_mh,FieldSet.new(:attribute,cols),update_select_ds,opts)
    end

    def self.update_attribute_values_incremental(attr_mh,array_slice_rows,cols_x,opts={})
      cols = cols_x
      cols += [:id] unless cols_x.include?(:id)
      update_rows = array_slice_rows.map do |r|
        value = incremental_value(:value_derived,r[:indexes],r[:array_slice])
        #TODO: unify with code in SQL::ArrayDataset
        (cols-[:value_derived]).inject({:value_derived => value}) do |h,col|
          v = r[col]
          h.merge(col => (v.kind_of?(Hash) or v.kind_of?(Array)) ? JSON.generate(v) : v)
        end
      end

      #TODO: see if can optimize to do multiple rows at once
      update_rows.map do |r|
        fs = Model::FieldSet.opt([:id]+(cols-[:id]).map{|col|{r[col] => col}},:attribute)
        wc={:id => r[:id]}
        update_select_ds = Model.get_objects_just_dataset(attr_mh,wc,fs)
        x=update_from_select(attr_mh,FieldSet.new(:attribute,cols-[:id]),update_select_ds,opts)
        x
      end.flatten
    end


    #TODO: this should probably go in db../update or sql
    def self.incremental_value(col,indexes,array_slice)
      pattern = Array.new
      replace = Array.new
      array_slice_ndx = 0
      replace_ndx = 1
      (0..indexes.max).each do |i|
        if indexes.include?(i)
          pattern << "{.+?}"
          replace << array_slice[array_slice_ndx]
          array_slice_ndx += 1
        else
          pattern << "({.+?})"
          replace << "\\#{replace_ndx}"
          replace_ndx += 1
        end
      end
      replace_string = replace.map{|x|(x.kind_of?(Hash) or x.kind_of?(Array)) ? JSON.generate(x) : x}.join(",")
      replace_case = :regexp_replace.sql_function(:value_derived,pattern.join(","),replace_string)
      new_case = JSON.generate(array_slice)
      SQL::ColRef.case{[[{:value_derived => nil},new_case],replace_case]}
    end


    def self.get_attribute_with_base_object(attr_idh,base_model_name)
      field_set = FieldSet.new(:attribute,[:id,:display_name,:value_asserted,"base_object_#{base_model_name}".to_sym])
      filter = [:and,[:eq,:id,attr_idh.get_id()]]
      ds = SearchObject.create_from_field_set(field_set,attr_idh[:c],filter).create_dataset()
      ds.all.first
    end

    def self.get_attributes_with_base_objects(attr_model_handle,attr_id_list,base_model_name)
      field_set = FieldSet.new(:attribute,[:id,:display_name,:value_asserted,"base_object_#{base_model_name}".to_sym])
      filter = [:or] + attr_id_list.map{|id|[:eq,:id,id]}
      ds = SearchObject.create_from_field_set(field_set,attr_model_handle[:c],filter).create_dataset()
      ds.all
    end

    def self.create_needed_l4_sap_attributes(cmp_id_handle,ipv4_host_addresses)
      component_id = cmp_id_handle.get_id()
      field_set = Model::FieldSet.new(:component,[:id,:display_name,:attributes])
     #TODO: allowing feature in until nest features in base services filter = [:and, [:eq, :component__id, component_id],[:eq, :basic_type,"service"]]
      filter = [:and, [:eq, :component__id, component_id]]
      global_wc = {:attribute__semantic_type_summary => "sap_config__l4"}
      ds = SearchObject.create_from_field_set(field_set,cmp_id_handle[:c],filter).create_dataset().where(global_wc)

      #should only be one attribute matching (or none)
      component = ds.all.first
      sap_config_attr = (component||{})[:attribute]
      return nil unless sap_config_attr
      sap_config_attr_idh = cmp_id_handle.createIDH(:guid => sap_config_attr[:id],:model_name => :attribute, :parent_model_name => :component)

      #cartesian product of sap_config(s) and host addreses
      new_sap_value_list = Array.new
      #TODO: if graph converted hased values into Model types then could just do sap_config_attr[:attribute_value]
      values = sap_config_attr[:value_asserted]||sap_config_attr[:value_derived]
      #values can be hash or array; determine by looking at semantic_type
      #TODO: may use instead look up from semantic type
      values = [values] unless values.kind_of?(Array)
      values.each do |sap_config|
        ipv4_host_addresses.each do |ipv4_addr|
          new_sap_value_list << sap_config.merge(:host_address => ipv4_addr)
        end
      end

      description_prefix = (component[:display_name]||"").split("::").map{|x|x.capitalize}.join(" ") 
      description = description_prefix.empty? ? "Service Access Point" : "#{description_prefix} SAP"

      new_sap_attr_rows =
        [{
           :ref => "sap__l4",
           :display_name => "sap__l4", 
           :component_component_id => component_id,
           :value_derived => new_sap_value_list,
           :is_port => true,
           :hidden => true,
           :data_type => "json",
           :description => description,
           #TODO: need the  => {"application" => service qualification)
           :semantic_type => {":array" => "sap__l4"},
           :semantic_type_summary => "sap__l4"
         }]

      attr_mh = sap_config_attr_idh.createMH()
      new_sap_attr_idh = create_from_rows(attr_mh,new_sap_attr_rows, :convert => true).first
      
      [sap_config_attr_idh,new_sap_attr_idh]
    end

    module LinkInfo
      def self.set_next_index!(attr)
        link_info = attr[:link_info] ||= Hash.new
        link_info["indexes"] ||= Array.new
        next_index = (link_info["indexes"].max||0)+1
        link_info["indexes"] << next_index
        next_index
      end
      def self.array_pointers(attr,index)
        link_info = attr[:link_info]||{}
        (link_info["array_pointers"]||{})[index.to_s]
      end
      def self.update_array_pointers!(attr,index,pointers)
        link_info = attr[:link_info] ||= Hash.new
        link_info["array_pointers"] ||= Hash.new
        link_info["array_pointers"][index.to_s] = pointers.map{|x|x.to_i}
      end
    end

   private
    ###### helper fns
    def self.propagate_changes(attr_changes) 
      AttributeLink.propagate(attr_changes.map{|x|x.id_handle},attr_changes.map{|x|x.state_change_id_handle})
    end

###################################################################
    ##TODO: need to go over each one below to see what we still should use

    def check_and_set_derived_relation!()
      ingress_objects = Model.get_objects(ModelHandle.new(id_handle[:c],:attribute_link),:output_id => self[:id])
      return nil if ingress_objects.nil?
      ingress_objects.each{ |input_obj|
        fn = AttributeLink::ret_function_if_can_determine(input_obj,self)
        check_and_set_derived_rel_from_link_fn!(fn)
      }
    end

    #sets this attribute derived relation from fn given as input; if error throws trap
    #TBD: may want to pass in more context about input so that can set fn
    def check_and_set_derived_rel_from_link_fn!(fn)
      return nil if fn.nil?
      if self[:function].nil?
        update(:function => fn)
        return nil
      end
      raise Error.new("mismatched link") 
    end

    ### virtual column defs
    # returns asserted first then derived

    def unknown_in_attribute_value()
      attr_value = attribute_value()
      return true if attr_value.nil?
      return nil unless self[:is_array]
      return nil unless attr_value.kind_of?(Array) #TBD: this should be error      
      attr_value.each{|v| return true if v.nil?}
      return nil
    end

    def assoc_components_on_nodes()
      parent_obj = get_parent_object()	
      return [] if parent_obj.nil?
      case parent_obj.relation_type
        when :node
          Array.new
        when :component
          parent_obj.get_objects_associated_nodes().map do |n|
            {:node => n, :component => parent_obj}
          end
        else
          raise Error.new("unexpected parent of attribute")
      end 
    end    
  end
end


module XYZ
  class DerivedValueFunction
    class << self
      def sap_from_config_and_ip(ip_addr,sap_config)
       #TBD: stub; ignores config constraints on sap_config
       return nil if ip_addr.nil? or sap_config.nil?
       port = sap_config[:network] ? sap_config[:network][:port] : nil
       return nil if port.nil?
       {
          :network => {
            :port => port,
            :addresses => [ip_addr]
          }
       }
      end
      
      def sap_ref_from_sap(sap)
        return nil if sap.nil?
        #TBD: stubbed to only handle limited cases
        raise ErrorNotImplemented.new("sap to sap ref function where not type 'network'") unless sap[:network]
        raise Error.new("network sap missing port number") unless sap[:network][:port]
        raise Error.new("network sap missing addresses") unless sap[:network][:addresses]
        raise ErrorNotImplemented.new("saps with multiple IP addresses") unless sap[:network][:addresses].size == 1
        {:network => {
           :port => sap[:network][:port],
           :address => sap[:network][:addresses][0]
          }
        }
      end
    end
  end
end
