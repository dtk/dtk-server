module XYZ
  class Attribute < Model
    set_relation_name(:attribute,:attribute)
    def self.up()
      external_ref_column_defs()

      #columns related to the value
      column :value_asserted, :json
      column :value_derived, :json
      column :value_actual, :json
      #TODO: may rename attribute_value to desired_value
      virtual_column :attribute_value, :type => :json, :local_dependencies => [:value_asserted,:value_derived],
        :sql_fn => SQL::ColRef.coalesce(:value_asserted,:value_derived)

      #columns related to the data/semantic type
      column :data_type, :varchar, :size => 25
      column :semantic_type, :json #points to structural info for a json varr #TODO: should this be a varchar instead; may need another field which is a pointer for attributes that are free form hashs w/o a seamntic type
      column :read_only, :boolean, :default => false #true means variable is automtcally set
      column :required, :boolean, :default => false #whether required for this attribute to have a value inorder to execute actions for parent component; TODO: may be indexed by action
      #setting on port type contrains whether a link can be connecetd to teh attribute
      column :port_type, :varchar, :size => 10 # null means no port; otherwise "input", "output", or "either"

      #columns related to links
      column :num_attached_input_links, :integer, :default => 0, :hidden => true
      column :num_attached_output_links, :integer, :default => 0, :hidden => true

      virtual_column :is_unset, :type => :boolean, :hidden => true, :local_dependencies => [:value_asserted,:value_derived,:data_type,:semantic_type]

      virtual_column :needs_to_be_set, :type => :boolean, :hidden => true, 
        :local_dependencies => [:value_asserted,:value_derived,:read_only,:required,:num_attached_output_links],
        :sql_fn => SQL.and({:attribute__value_asserted => nil},{:attribute__value_derived => nil},
                           SQL.not(:attribute__read_only),
                           :attribute__required,
                           {:attribute__num_attached_output_links => 0})

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
           :join_cond=>{:input_id=> :attribute__id},
           :cols=>[:input_id,:output_id,:function,:function_index]
         },
         {
           :model_name => :attribute,
           :join_type => :inner,
           :join_cond=>{:id=> :attribute_link__output_id},
           :cols=>[:id, :value_asserted,:value_derived]
         }
        ]


    end
    ### virtual column defs
    def attribute_value()
      self[:value_asserted] || self[:value_derived]
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
      component_name = (self[:component]||{})[:display_name]
      component_el = lambda{|x|x ? "[#{x}]" : ""}.call(component_name)
      node_or_group_el = lambda{|x|x ? "[#{x}]" : ""}.call(node_or_group_name)
      prefix, attr_el = (self[:display_name] =~ /(.*?)(\[.*\])/; [$1,$2])
      prefix + node_or_group_el + component_el + attr_el
    end


    def self.update_from_hash_assignments(id_handle,hash_assigns,opts={})
      Model.update_from_hash_assignments(id_handle,hash_assigns,opts)
      #TODO: should this functionality below be called from within Attribute.update_from_hash_assignments or instead be called
      # from ahigher level fn?
      #if there is an actual change then set up actions to make the change; check whetehr there is an actual change is by 
      # comparing asserted value to attribute_actual; actual change is if attribute_actual is not null (meaning it has been set) and 
      #different from changed_value 
      changed_value = hash_assigns[:value_asserted] #TODO: check whether actual change
      return nil if changed_value.nil?

      #TODO any more efficient way to get action_parent_idh and parent_idh info
      action_parent_idh = id_handle.get_top_container_id_handle(:datacenter)
      return nil unless action_parent_idh #this would happend if top container is not a datacenter TODO: see if this should be "trapped" at higher level
      base_object = get_attribute_with_base_object(id_handle,:node_group)
      new_item_hash = {
        :new_item => id_handle,
        :parent => action_parent_idh
      }
      new_item_hash.merge!(:base_object => base_object) if base_object
      action_id_handle = Action.create_pending_change_item(new_item_hash)
      propagate_changes([AttributeChange.new(id_handle,changed_value,action_id_handle)]) if action_id_handle
    end

    def self.get_attribute_with_base_object(attr_id_handle,base_model_name)
      field_set = FieldSet.new(:attribute,[:id,:display_name,"base_object_#{base_model_name}".to_sym])
      filter = [:and,[:eq,:id,attr_id_handle.get_id()]]
      ds = SearchObject.create_from_field_set(field_set,attr_id_handle[:c],filter).create_dataset()
      ds.all.first
    end

    def self.get_attributes_with_base_objects(attr_model_handle,attr_id_list,base_model_name)
      field_set = FieldSet.new(:attribute,[:id,:display_name,"base_object_#{base_model_name}".to_sym])
      filter = [:or] + attr_id_list.map{|id|[:eq,:id,id]}
      ds = SearchObject.create_from_field_set(field_set,attr_model_handle[:c],filter).create_dataset()
      ds.all
    end

    def self.add_needed_ipv4_sap_attributes(cmp_id_handle,ipv4_host_addresses)
      field_set = Model::FieldSet.new(:component,[:id,:attributes])
      filter = [:and, [:eq, :component__id, cmp_id_handle.get_id()],[:eq, :basic_type,"service"]]
      global_wc = {:attribute__display_name => "port[sap_config][ipv4]"}
      ds = SearchObject.create_from_field_set(field_set,cmp_id_handle[:c],filter).create_dataset().where(global_wc)
      sap_configs = ds.all
      return nil if sap_configs.empty?
      new_sap_attr_rows = Array.new
      ipv4_host_addresses.each do |ipv4_addr|
        sap_configs.each do |sap_config|
          value_derived = (sap_config[:attribute][:value_asserted]||sap_config[:attribute][:value_derived]).map{|x|x.merge(:host_address => ipv4_addr)}
          new_sap_attr_rows <<  {
            :ref => "port[sap][ipv4]",
            :display_name => "port[sap][ipv4]", 
            :component_component_id => sap_config[:id],
            :value_derived => value_derived,
            :port_type => "input",
            :data_type => "json",
            :description => "mysql ip service access point configuration",
            #TODO: need the  => {"application" => service qualification)
            :semantic_type => {":array" => "sap[ipv4]"},
            :num_attached_input_links => 2
          }
        end
      end
      attr_mh = cmp_id_handle.createMH(:model_name => :attribute, :parent_model_name => :component)
      create_from_rows(attr_mh,new_sap_attr_rows, :convert => true)
    end


   private
    ###### helper fns
    def self.propagate_changes(attr_changes) 
      new_changes = AttributeLink.propagate_when_eq_links(attr_changes)
    end

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
