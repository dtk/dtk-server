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

      #TODO: these may be redundant; if so wil remove one
      column :read_only, :boolean, :default => false 
      column :dynamic, :boolean, :default => false #means dynamically set by an executable action

      column :required, :boolean, :default => false #whether required for this attribute to have a value inorder to execute actions for parent component; TODO: may be indexed by action


      #columns related to links
      column :is_port, :boolean, :default => false
      virtual_column :port_is_external, :type => :boolean, :hidden => true, :local_dependencies => [:is_port,:semantic_type_summary]
      virtual_column :port_type, :type => :varchar, :hidden => true, :local_dependencies => [:is_port,:semantic_type_summary]

      column :link_info, :json, :ret_keys_as_symbols => false
     
      virtual_column :is_unset, :type => :boolean, :hidden => true, :local_dependencies => [:value_asserted,:value_derived,:data_type,:semantic_type]

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

      virtual_column :parent_name, :possible_parents => [:component,:node]
      many_to_one :component, :node

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

=begin TODO: would like "search object link form"
also related is allowing omission of columns mmentioned in jon condition; post processing when entering vcol def would added these in
         { {:relation => :this
           },
           {:relation => :component,
            :columns => [:id, :display_name]
           },
           [
             {:relation => :node,
              :columns => [:id, :display_name],
              :params => [:datacenter_id]
             },
             {:relation => :node_group,
              :columns => [:id, :display_name],
              :params => [:datacenter_id]
              }
           ]
         }
=end
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
    def attribute_value()
      self[:value_asserted] || self[:value_derived]
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

    def is_unset()
      #care must be takedn so this is three-valued
      return true if attribute_value().nil?
      return false unless self[:data_type] == "json"
      return nil unless self[:semantic_type]
      has_req_fields = AttributeComplexType.has_required_fields_given_semantic_type?(attribute_value(),self[:semantic_type])
      return nil if has_req_fields.nil?
      has_req_fields ? false : true
    end

    def qualified_attribute_name_under_node()
      qualified_attribute_name_aux()
    end
    def qualified_attribute_id_under_node()
      qualified_attribute_id_aux()
    end

    def qualified_attribute_name()
      node_or_group_name =
        if self[:node] then self[:node][:display_name]
        elsif self[:node_group] then self[:node_group][:display_name]
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
    ### object procssing and access functions

    def qualified_attribute_name_aux(node_or_group_name=nil)
      cmp_name = (self[:component]||{})[:display_name]
      #strip what will be recipe name
      cmp_el = cmp_name ? cmp_name.gsub(/::.+$/,"") : nil
      attr_name = self[:display_name]
      token_array = ([node_or_group_name,cmp_el] + Aux.tokenize_bracket_name(attr_name)).compact
      Aux.put_in_bracket_form(token_array)
    end
    def qualified_attribute_id_aux(node_or_group_id_formatted=nil)
      cmp_id_formatted = AttributeComplexType.container_id(:component,(self[:component]||{})[:id])
      attr_id_formatted = AttributeComplexType.container_id(:attribute,self[:id])
      item_path = AttributeComplexType.item_path_token_array(self)||[]
      token_array = ([node_or_group_id_formatted,cmp_id_formatted,attr_id_formatted] + item_path).compact
      Aux.put_in_bracket_form(token_array)
    end

    #TODO: may remove
    def self.update_attributes(attr_mh,attribute_rows)
      return Array.new if attribute_rows.empty?
      unpruned_update_select_ds = SQL::ArrayDataset.create(db,attribute_rows,attr_mh,:convert_for_update => true)

      attr_ds = get_objects_just_dataset(attr_mh,nil,FieldSet.opt([{:id => :id2},{:value_asserted => :old_value_asserted}],:attribute))
      #add qualification so that only updated values are set
      join_cond = SQL.and({:id => :id2},SQL.not_equal(:value_asserted,:old_value_asserted))
                          
      update_select_ds =  unpruned_update_select_ds.join_table(:inner,attr_ds,join_cond)

      returning_cols_opts = {:returning_cols => [:id,:value_asserted,:old_value_asserted]}
      changed_attrs = update_from_select(attr_mh,FieldSet.new(:attribute,[:value_asserted]),update_select_ds,returning_cols_opts)
      return nil if changed_attrs.empty?
      #TODO: add to change actions:
      pp [:changed_attrs,changed_attrs]
    end

    def self.update_and_propagate_attribute_value(attr_idh,value_asserted)
      base_object = get_attribute_with_base_object(attr_idh,attr_idh[:parent_model_name])
      old_value = (base_object||{})[:value_asserted]

      new_val_rows = [{:id => attr_idh.get_id(),:value_asserted => value_asserted}]
      changed_ids = update_changed_values(attr_idh.createMH(),new_val_rows,:value_asserted)
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

    def self.update_changed_values(attr_mh,new_val_rows,value_type)
      update_select_ds = SQL::ArrayDataset.create(db,new_val_rows,attr_mh)
      opts = {:update_only_if_change => [value_type],:returning_cols => [:id]}
      update_from_select(attr_mh,FieldSet.new(:attribute,[value_type]),update_select_ds,opts)
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

    def self.add_needed_ipv4_sap_attributes(cmp_id_handle,ipv4_host_addresses)
      component_id = cmp_id_handle.get_id()
      field_set = Model::FieldSet.new(:component,[:id,:display_name,:attributes])
     #TODO: allowing feature in until nest features in base services filter = [:and, [:eq, :component__id, component_id],[:eq, :basic_type,"service"]]
      filter = [:and, [:eq, :component__id, component_id]]
      global_wc = {:attribute__semantic_type_summary => "sap_config[ipv4]"}
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
          :ref => "sap[ipv4]",
          :display_name => "sap[ipv4]", 
          :component_component_id => component_id,
          :value_derived => new_sap_value_list,
          :is_port => true,
          :data_type => "json",
          :description => description,
          #TODO: need the  => {"application" => service qualification)
          :semantic_type => {":array" => "sap[ipv4]"},
          :semantic_type_summary => "sap[ipv4]"
         }]

      attr_mh = sap_config_attr_idh.createMH()
      new_sap_attr_idh = create_from_rows(attr_mh,new_sap_attr_rows, :convert => true).first
      
      [sap_config_attr_idh,new_sap_attr_idh]
    end

    class LinkInfo < HashObject
      def initialize(link_info_attr_val)
        super(link_info_attr_val||{})
      end
      def set_next_index!()
        self["indexes"] ||= Array.new
        next_index = (self["indexes"].max||0)+1
        self["indexes"] << next_index
        next_index
      end
      def hash_value()
        self
      end
      def array_pointers(index)
        (self["array_pointers"]||{})[index.to_s]
      end
      def update_array_pointers!(index,pointers)
        self["array_pointers"] ||= Hash.new
        self["array_pointers"][index.to_s] = pointers.map{|x|x.to_i}
      end
    end

   private
    ###### helper fns
    def self.propagate_changes(attr_changes) 
      AttributeLink.propagate(attr_changes.map{|x|x.id_handle})
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
