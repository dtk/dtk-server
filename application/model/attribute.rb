require  File.expand_path('attribute/dependency_analysis', File.dirname(__FILE__))
require  File.expand_path('attribute/group', File.dirname(__FILE__))
require  File.expand_path('attribute/guard', File.dirname(__FILE__))
require  File.expand_path('attribute/complex_type', File.dirname(__FILE__))
require  File.expand_path('attribute/datatype', File.dirname(__FILE__))
require  File.expand_path('attribute/propagate_changes', File.dirname(__FILE__))
require  File.expand_path('attribute/update_derived_values', File.dirname(__FILE__))
module XYZ
  class Attribute < Model
    include AttributeGroupInstanceMixin
    include AttributeDatatype
    extend AttrDepAnalaysisClassMixin
    extend AttributeGroupClassMixin
    extend AttributeGuardClassMixin
    extend  AttrPropagateChangesClassMixin

    set_relation_name(:attribute,:attribute)

    def self.up()
      external_ref_column_defs()
      virtual_column :config_agent_type, :type => :string, :local_dependencies => [:external_ref]

      #columns related to the value
      column :value_asserted, :json, :ret_keys_as_symbols => false
      column :value_derived, :json, :ret_keys_as_symbols => false
      column :is_instance_value, :boolean, :default => false #to distinguish between when value_asserted is from default versus directly asserted
      #TODO: not used yet column :value_actual, :json, :ret_keys_as_symbols => false
      #TODO: may rename attribute_value to desired_value
      virtual_column :attribute_value, :type => :json, :local_dependencies => [:value_asserted,:value_derived],
        :sql_fn => SQL::ColRef.coalesce(:value_asserted,:value_derived)

      #columns related to the data/semantic type
      column :data_type, :varchar, :size => 25
      column :semantic_type, :json #points to structural info for a json var 
      column :semantic_type_summary, :varchar, :size => 25 #for efficiency optional token that summarizes info from semantic_type
      virtual_column :semantic_type_object, :type => :object, :hidden => true, :local_dependencies => [:semantic_type]

      ###cols that relate to who or what can or does change the attribute
      #TODO: need to clearly relate these four; may get rid of read_only
      column :read_only, :boolean, :default => false 
      column :dynamic, :boolean, :default => false #means dynamically set by an executable action
      column :cannot_change, :boolean, :default => false


      column :required, :boolean, :default => false #whether required for this attribute to have a value inorder to execute actions for parent component; TODO: may be indexed by action
      column :hidden, :boolean, :default => false

      #columns related to links
      #TODO: for succinctness may use less staorage and colapse a number of port attributes
      column :port_location, :varchar, :size => 10 #if set is override for port direction: east | west | south | north
      column :is_port, :boolean, :default => false
      column :port_type_asserted, :varchar, :size => 10
      column :is_external, :boolean
      virtual_column :port_type, :type => :varchar, :hidden => true, :local_dependencies => [:dynamic,:is_port,:port_type_asserted,:semantic_type_summary]
      virtual_column :port_is_external, :type => :boolean, :hidden => true, :local_dependencies => [:is_port,:is_external,:semantic_type_summary]

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
           :cols => [:id,:display_name,:component_type,:most_specific_type,:connectivity_profile_external,:ancestor_id,:node_node_id,:extended_base_id]
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
           :cols=>[:output_id,:input_id,:function,:index_map]
         },
         {
           :model_name => :attribute,
           :alias => :input_attribute,
           :join_type => :inner,
           :join_cond=>{:id=> :attribute_link__input_id},
           :cols=>[:id, :value_asserted,:value_derived,:semantic_type,:display_name]
         }
        ]

    end

    ### virtual column defs
    def config_agent_type()
      external_ref_type = (self[:external_ref]||{})[:type]
      case external_ref_type
       when "chef_attribute" then "chef"
       when "puppet_attribute" then "puppet"
      end
    end

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

    #TODO: deprecate
    def needs_to_be_set()
      attribute_value().nil? and self[:required] and not self[:read_only]
    end

    #TODO: modify these so dont look up AttributeSemantic
    def port_is_external()
      return self[:is_external] unless self[:is_external].nil?
      return nil unless self[:is_port]
      return nil unless self[:semantic_type_summary]
      (AttributeSemantic::Info[self[:semantic_type_summary]]||{})[:external]
    end
    #TODO: modify these so dont look up AttributeSemantic
    def port_type()
      return self[:port_type_asserted] unless self[:port_type_asserted].nil?
      return nil unless self[:is_port]
      return "output" if self[:dynamic]
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
    def self.update_from_hash_assignments(id_handle,hash,opts={})
      update_attribute_def(id_handle,hash,opts)
    end
    def self.update_attribute_def(id_handle,hash,opts={})
      attr = id_handle.create_object().update_object!(:config_agent_type,:component_parent)
      aug_hash = hash.merge(:config_agent_type => attr[:config_agent_type], :component_type => attr[:component_parent][:component_type])
      internal_form = attr_def_to_internal_form(aug_hash)
      internal_form
#      Model.update_from_hash_assignments(id_handle,internal_form,opts)
    end

    def get_attribute_def()
      update_object!(:id,:display_name,:value_asserted,:required,:external_ref,:dyanmic,:data_type,:semantic_type,:semantic_type_summary,:config_agent_type)
      ret = Hash.new
      [:id,:required,:dyanmic].each{|k|ret[k] = self[k] if self[k]}
      ret[:field_name] = self[:display_name]
      
      #put in optional key that inidcates implementation attribute
      impl_attr = ret_implementation_attribute_name_and_type()
      #default is that implementation attribute name same as r8 attribute name; so omit if default
      unless self[:display_name] == impl_attr[:name]
        case impl_attr[:type].to_sym
          when :puppet then ret.merge!(:puppet_attribute_name => impl_attr[:name])
          when :chef then ret.merge!(:chef_attribute_name => impl_attr[:name])
        end
      end
      ret[:datatype] = ret_datatype()

      default_info = ret_default_info()
      ret[:default_info] = default_info if default_info
      
      ret
    end
    
    #============= 
    def self.update_port_info(attr_mh,attr_link_rows_created)
      attr_port_info = Array.new
      attr_link_rows_created.each do |row|
        #TODO: row[:type].nil? test need sto be changed if attribute link type default is no longer "external"
        if row[:type].nil? or row[:type] == "external"
          [["input",row[:input_id]],["output",row[:output_id]]].each do |(dir,id)|
            attr_port_info << {:id => id, :port_type_asserted => dir, :is_port => true, :is_external => true}
          end 
        end
      end
      update_from_rows(attr_mh,attr_port_info) unless attr_port_info.empty?
    end

   private
    def ret_implementation_attribute_name_and_type()
      config_agent = ConfigAgent.load(self[:config_agent_type])
      config_agent && config_agent.ret_attribute_name_and_type(self)
    end


    def self.attr_def_to_internal_form(hash)
      ret = Hash.new
      [:required,:id].each{|k|ret[k] = hash[k] if hash.has_key?(k)}
      ret[:display_name] = hash[:field_name] if hash.has_key?(:field_name)
      type_info = AttributeDatatype.attr_def_to_internal_form(hash)
      type_info.each{|k,v|ret[k] = v}
      ret[:external_ref] = attr_def_to_internal_form__external_ref(hash)
      ret[:value_asserted] = hash[:default_info] if hash.has_key?(:default_info)
      ret
    end

    def self.attr_def_to_internal_form__external_ref(hash)
      config_agent = ConfigAgent.load(hash[:config_agent_type])
      config_agent.ret_attribute_external_ref(:component_type => hash[:component_type], :field_name => hash[:field_name])
    end

    #####################
   public
    def get_constraints!(opts={})
      Log.error("opts not implemented yet") unless opts.empty?
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

    def self.unravelled_value(val,path)
      return nil unless Aux.can_take_index?(val)
      path.size == 1 ? val[path.first] : unravelled_value(val[path.first],path[1..path.size-1])
    end

    def self.json_form(x)
      begin
        JSON.parse(x)
      rescue Exception
        x
      end
    end

   public

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
