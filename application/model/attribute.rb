files =
  [
   'dependency_analysis',
   'group',
   'guard',
   'complex_type',
   'datatype',
   'propagate_changes',
   'update_derived_values',
   'meta'
  ]
r8_nested_require('attribute',files)
module XYZ
  class Attribute < Model
    r8_nested_require('attribute','pattern')
    r8_nested_require('attribute','legal_value')
    r8_nested_require('attribute','special_processing')
    include AttributeGroupInstanceMixin
    include AttributeDatatype
    extend AttrDepAnalaysisClassMixin
    extend AttributeGroupClassMixin
    extend AttributeGuardClassMixin
    extend  AttrPropagateChangesClassMixin

    set_relation_name(:attribute,:attribute)
    extend AttributeMetaClassMixin

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

    #FOR_AMAR
    def self.aug_attr_list_from_state_change_list(state_change_list)
      ret = Array.new
      #get all relevant attributes by first finding component ids
      ndx_scs = Hash.new
      state_change_list.each do |node_change_list|
        node_change_list.each do |sc|
          ndx_scs[sc[:component][:id]] ||= sc
        end
      end
      return ret if ndx_scs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_component_id,:attribute_value,:required,:dynamic],
        :filter => [:oneof,:component_component_id, ndx_scs.keys]
      }
      attr_mh = state_change_list.first.first[:component].model_handle(:attribute)
      ret = get_objs(attr_mh,sp_hash)
      ret.each do |attr|
        sc = ndx_scs[attr[:component_component_id]]
        attr.merge!(:component => sc[:component], :node => sc[:node])
      end
      ret
    end

    def self.aug_attr_list_from_component_actions(component_actions)
      ret = Array.new
      node_ids = Hash.new
      component_actions.each do |action|
        AttributeComplexType.flatten_attribute_list(action[:attributes],:flatten_nil_value=>true).each do |attr|
          cmp = action[:component]
          node_ids[cmp[:node_node_id]] ||= true
          ret << attr.merge(:component => action[:component])
        end
      end
      return ret if ret.empty?
      #get node info
      node_mh = component_actions.first[:component].model_handle(:node)
      sp_hash = {
        :cols => [:id,:display_name,:group_id],
        :filter => [:oneof,:id,node_ids.keys]
      }
      ndx_nodes = get_objs(node_mh,sp_hash).inject(Hash.new){|h,n|h.merge(n[:id]=>n)}
      ret.each do |r|
        r.merge!(:node => ndx_nodes[r[:component][:node_node_id]])
      end
      ret
    end

    def self.augmented_attribute_list_from_task(task,opts={})
      component_actions = task.component_actions
      ret = Array.new 
      ndx_nodes = Hash.new
      component_actions.each do |action|
        AttributeComplexType.flatten_attribute_list(action[:attributes],:flatten_nil_value=>true).each do |attr|
          ret << attr.merge(:component => action[:component], :node => action[:node],:task_id => task[:id])
        end
        if opts[:include_node_attributes]
          node = action[:node]
          ndx_nodes[node[:id]] ||= node
        end
      end
      if opts[:include_node_attributes]
        #TODO: none need flattening now
        #adding any nodes that are only node_level
        task.node_level_actions().each do |action|
          node = action[:node]
          ndx_nodes[node[:id]] ||= node
        end
        node_idhs = ndx_nodes.values.map{|n|n.id_handle()}
        add_filter = [:eq,:required,true]
        cols = [:id,:group_id,:display_name,:node_node_id,:required,:value_derived,:value_asserted,:dynamic,:port_type_asserted,:is_port,:semantic_type_summary]
        Node.get_node_level_attributes(node_idhs,cols,add_filter).each do |attr|
          ret << attr.merge(:node => ndx_nodes[attr[:node_node_id]],:task_id => task[:id])
        end
      end
      ret
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
      end
      qualified_attribute_name_aux(node_or_group_name)
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

    def print_form(display_name_prefix=nil)
      update_object!(*UpdateCols)
      #TODO: handle complex attributes better and omit derived attributes; may also indicate whether there is an override
      display_name = "#{display_name_prefix}#{self[:display_name]}"
      datatype =
        case self[:data_type]
         when "integer" then "integer"
         when "boolean" then "boolean"
         else "string"
        end
      value = info_about_attr_value(self[:attribute_value])
      attr_info = {
        :display_name => display_name, 
        :datatype => datatype,
        :description => self[:description]||self[:display_name]
      }
      attr_info.merge!(:value => value) if value
      hash_subset(*UnchangedDisplayCols).merge(attr_info)
    end
    UnchangedDisplayCols = [:id,:required]
    UpdateCols = UnchangedDisplayCols + [:description,:display_name,:data_type,:value_derived,:value_asserted]

    def required_unset_attribute?()
      #port_type depends on :port_type_asserted,:is_port,:semantic_type_summary and :dynamic
      update_object!(:required,:value_derived,:value_asserted,:port_type_asserted,:is_port,:semantic_type_summary,:dynamic)
      if self[:required] and self[:attribute_value].nil? and not self[:dynamic]
        if self[:port_type] == "input"
          not has_input_link?()
        else
          true
        end
      end
    end
    
   private
    def has_input_link?()
      sp_hash = {
        :cols => [:id],
        :filter => [:eq,:input_id,id()]
      }
      not get_obj(model_handle(:attribute_link),sp_hash).empty?
    end

    def info_about_attr_value(value)
      #TODO: handle complex attributes better 
      if value
        if value.kind_of?(Array)
          #value.map{|el|info_about_attr_value(el)}
          value.inspect
        elsif value.kind_of?(Hash)
          ret = Hash.new
          value.each do |k,v|
            ret[k] = info_about_attr_value(v)
          end
          ret
        elsif [String,Fixnum,TrueClass,FalseClass].find{|t|value.kind_of?(t)}
          value
        else
          value.inspect
        end
      end
    end

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

   public

    def self.create_needed_l4_sap_attributes(cmp_id_handle,ipv4_host_addresses)
      #TODO: cleanup to use newer model access fns
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
