# TODO: move files to inside DTK::Attribute
files =
  [
   'dependency_analysis',
   'group',
   'complex_type'
  ]
r8_nested_require('attribute',files)
module DTK
  class Attribute < Model
    set_relation_name(:attribute,:attribute)

    r8_nested_require('attribute','get_method')
    r8_nested_require('attribute','meta')
    r8_nested_require('attribute','datatype')
    r8_nested_require('attribute','propagate_changes')
    r8_nested_require('attribute','pattern')
    r8_nested_require('attribute','legal_value')
    r8_nested_require('attribute','special_processing')
    r8_nested_require('attribute','constant')
    r8_nested_require('attribute','print_form')
    r8_nested_require('attribute','semantic_datatype')
    r8_nested_require('attribute','dangling_links_class_mixin')
    r8_nested_require('attribute','update_derived_values')

    include GetMethod::Mixin
    extend GetMethod::ClassMixin
    include AttributeGroupInstanceMixin
    include DatatypeMixin
    extend AttrDepAnalaysisClassMixin
    extend AttributeGroupClassMixin
    include ConstantMixin
    include PrintFormMixin
    extend PrintFormClassMixin
    extend PropagateChangesClassMixin
    extend MetaClassMixin
    extend DanglingLinksClassMixin

    def self.common_columns
      [:id,:display_name,:group_id,:hidden,:description,:component_component_id,:value_derived,:value_asserted,:semantic_data_type,:semantic_type,:semantic_type_summary,:data_type,:required,:dynamic,:cannot_change,:port_type_asserted,:is_port,:external_ref,:read_only,:tags]
    end

    def self.legal_display_name?(display_name)
      display_name =~ LegalDisplayName
    end
    LegalDisplayName = /^[a-zA-Z0-9_\[\]\.-]+$/

    def self.default_title_field
      'name'
    end

    # TODO: may make this a real field in attribute
    def title
      self[:attribute_value] if is_title_attribute?()
    end

    def is_title_attribute?
      get_field?(:display_name) == "name" || ext_ref_indicates_title?(get_field?(:external_ref))
    end

    def ext_ref_indicates_title?(ext_ref)
      ret = 
        if ext_ref[:type] == "puppet_attribute"
          if path = ext_ref[:path]
            path =~ /\[name\]$/
          end
        end
      !!ret
    end
    private :ext_ref_indicates_title?

    def config_agent_type
      external_ref_type = (self[:external_ref]||{})[:type]
      case external_ref_type
       when "chef_attribute" then "chef"
       when "puppet_attribute" then "puppet"
      end
    end

    def filter_when_listing?(opts={})
      if self[:hidden]
        return true
      end
      if opts[:editable] && is_readonly?
        return true
      end
      if filter_base_tags = opts[:tags]
        common_tags = (base_tags?()||[]) & filter_base_tags.map{|x|x.to_sym}
        return common_tags.empty?
      end
      false
    end

    # assume this is called when :tags is pull from db
    def base_tags?
      if self[:tags] = HierarchicalTags.reify(self[:tags])
        self[:tags].base_tags?()
      end
    end

    def self.create_or_modify_field_def(parent,field_def)
      attr_mh = parent.model_handle.create_childMH(:attribute)
      attr_hash = Aux::hash_subset(field_def,CreateFields)
      unless attr_hash[:display_name]
        raise Error.new("display_name required in field_def")
      end
      attr_hash[:ref] = attr_hash[:display_name]
      attr_hash[:semantic_data_type] ||= SemanticDatatype.default().to_s
      attr_hash[:data_type] ||= SemanticDatatype.datatype(attr_hash[:semantic_data_type]).to_s
      # TODO: may use a method rather than below that is more efficient; below returns alll children rather than filtered search
      Model.modify_children_from_rows(attr_mh,parent.id_handle,[attr_hash],[:ref],update_matching: true,no_delete: true)
    end
    CreateFields = [:display_name,:data_type,:dynamic,:required,:semantic_data_type].map{|sym|{sym.to_s => sym}} + [{'default' => :value_asserted}]

    # TODO: collapse this and 4 fields used here
    def is_readonly?
      update_object!(*(VirtulaDependency.port_type()+[:read_only,:dynamic,:cannot_change]))
      (self[:port_type] == "input") || self[:read_only] || self[:dynamic] || self[:cannot_change] 
    end

    def attribute_value
      self[:value_asserted] || self[:value_derived]
    end

    def semantic_type_object
      SemanticType.create_from_attribute(self)
    end

    # TODO: modify these so dont look up AttributeSemantic
    def port_is_external
      return self[:is_external] unless self[:is_external].nil?
      return nil unless self[:is_port]
      return nil unless self[:semantic_type_summary]
      (AttributeSemantic::Info[self[:semantic_type_summary]]||{})[:external]
    end
    # TODO: modify these so dont look up AttributeSemantic
    def port_type
      return self[:port_type_asserted] unless self[:port_type_asserted].nil?
      return nil unless self[:is_port]
      return "output" if self[:dynamic]
      return nil unless self[:semantic_type_summary]
      (AttributeSemantic::Info[self[:semantic_type_summary]]||{})[:port_type]
    end

    def is_unset
      # care must be takedn so this is three-valued
      return true if attribute_value().nil?
      return false unless self[:data_type] == "json"
      return nil unless self[:semantic_type]
      has_req_fields = AttributeComplexType.has_required_fields_given_semantic_type?(attribute_value(),self[:semantic_type])
      return nil if has_req_fields.nil?
      has_req_fields ? false : true
    end

    # FOR_AMAR
    def self.aug_attr_list_from_state_change_list(state_change_list)
      ret = []
      # get all relevant attributes by first finding component ids
      ndx_scs = {}
      state_change_list.each do |node_change_list|
        node_change_list.each do |sc|
          ndx_scs[sc[:component][:id]] ||= sc
        end
      end
      return ret if ndx_scs.empty?
      sp_hash = {
        cols: [:id,:group_id,:display_name,:component_component_id,:attribute_value,:required,:dynamic],
        filter: [:oneof,:component_component_id, ndx_scs.keys]
      }
      attr_mh = state_change_list.first.first[:component].model_handle(:attribute)
      ret = get_objs(attr_mh,sp_hash)
      ret.each do |attr|
        sc = ndx_scs[attr[:component_component_id]]
        attr.merge!(component: sc[:component], node: sc[:node])
      end
      ret
    end

    def set_attribute_value(attribute_value)
      # unless SemanticDatatype.is_valid?(self[:semantic_data_type],attribute_value)
      #   raise ErrorUsage.new("The value (#{value.inspect}) is not of type (#{semantic_data_type})")
      # end
      update(value_asserted: attribute_value)
      self[:value_asserted] = attribute_value
    end

    def self.augmented_attribute_list_from_task(task,opts={})
      component_actions = task.component_actions
      ret = [] 
      ndx_nodes = {}
      component_actions.each do |action|
        AttributeComplexType.flatten_attribute_list(action[:attributes],flatten_nil_value: true).each do |attr|
          ret << attr.merge(component: action[:component], node: action[:node],task_id: task[:id])
        end
        if opts[:include_node_attributes]
          node = action[:node]
          ndx_nodes[node[:id]] ||= node
        end
      end
      if opts[:include_node_attributes]
        # TODO: none need flattening now
        # adding any nodes that are only node_level
        task.node_level_actions().each do |action|
          node = action[:node]
          ndx_nodes[node[:id]] ||= node
        end
        node_idhs = ndx_nodes.values.map{|n|n.id_handle()}
        add_filter = [:eq,:required,true]
        cols = [:id,:group_id,:display_name,:node_node_id,:required,:value_derived,:value_asserted,:dynamic,:port_type_asserted,:is_port,:semantic_type_summary]
        Node.get_node_level_attributes(node_idhs,cols: cols,add_filter: add_filter).each do |attr|
          ret << attr.merge(node: ndx_nodes[attr[:node_node_id]],task_id: task[:id])
        end
      end
      ret
    end

    def unraveled_attribute_id
      qualified_attribute_id_aux()
    end

    # TODO: may deprecate below
    def qualified_attribute_name_under_node
      qualified_attribute_name_aux()
    end

    def qualified_attribute_id_under_node
      qualified_attribute_id_aux()
    end

    def qualified_attribute_name
      node_or_group_name = self.key?(:node) ? self[:node][:display_name] : nil
      qualified_attribute_name_aux(node_or_group_name)
    end

    def id_info_uri
      (self[:id_info]||{})[:uri]
    end

    #######################
    ######### Model apis
    def self.update_from_hash_assignments(id_handle,hash,opts={})
      update_attribute_def(id_handle,hash,opts)
    end
    def self.update_attribute_def(id_handle,hash,_opts={})
      attr = id_handle.create_object().update_object!(:config_agent_type,:component_parent)
      aug_hash = hash.merge(config_agent_type: attr[:config_agent_type], component_type: attr[:component_parent][:component_type])
      internal_form = attr_def_to_internal_form(aug_hash)
      internal_form
      #      Model.update_from_hash_assignments(id_handle,internal_form,opts)
    end

    def print_path(component)
      return "cmp[#{component[:display_name].gsub('__','::')}]/#{self[:display_name]}"
    end
    
    #============= 
    def self.update_port_info(attr_mh,attr_link_rows_created)
      attr_port_info = []
      attr_link_rows_created.each do |row|
        # TODO: row[:type].nil? test need sto be changed if attribute link type default is no longer "external"
        if row[:type].nil? || row[:type] == "external"
          [["input",row[:input_id]],["output",row[:output_id]]].each do |(dir,id)|
            attr_port_info << {id: id, port_type_asserted: dir, is_port: true, is_external: true}
          end 
        end
      end
      update_from_rows(attr_mh,attr_port_info) unless attr_port_info.empty?
    end

    def required_unset_attribute?
      # port_type depends on :port_type_asserted,:is_port,:semantic_type_summary and :dynamic
      update_object!(:required,:value_derived,:value_asserted,:port_type_asserted,:is_port,:semantic_type_summary,:dynamic)
      if self[:required] && self[:attribute_value].nil? and not self[:dynamic]
        if self[:port_type] == "input"
          not has_input_link?()
        else
          true
        end
      end
    end
    
    private

    def has_input_link?
      sp_hash = {
        cols: [:id],
        filter: [:eq,:input_id,id()]
      }
      not get_obj(model_handle(:attribute_link),sp_hash).empty?
    end

    def self.attr_def_to_internal_form(hash)
      ret = {}
      [:required,:id].each{ |k| ret[k] = hash[k] if hash.key?(k) }
      ret[:display_name] = hash[:field_name] if hash.key?(:field_name)
      type_info = Datatype.attr_def_to_internal_form(hash)
      type_info.each{ |k,v| ret[k] = v }
      ret[:external_ref] = attr_def_to_internal_form__external_ref(hash)
      ret[:value_asserted] = hash[:default_info] if hash.key?(:default_info)
      ret
    end

    def self.attr_def_to_internal_form__external_ref(hash)
      config_agent = ConfigAgent.load(hash[:config_agent_type])
      config_agent.ret_attribute_external_ref(component_type: hash[:component_type], field_name: hash[:field_name])
    end

    #####################

    public

    ### object procssing and access functions
    def qualified_attribute_name_aux(node_or_group_name=nil)
      cmp_name = self.key?(:component) ? self[:component][:display_name] : nil
      # strip what will be recipe name
      cmp_el = cmp_name ? cmp_name.gsub(/::.+$/,"") : nil
      attr_name = self[:display_name]
      token_array = ([node_or_group_name,cmp_el] + Aux.tokenize_bracket_name(attr_name)).compact
      AttributeComplexType.serialze(token_array)
    end

    def qualified_attribute_id_aux(node_or_group_id_formatted=nil)
      cmp_id = self.key?(:component) ? self[:component][:id] : nil
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
      # TODO: cleanup to use newer model access fns
      component_id = cmp_id_handle.get_id()
      field_set = Model::FieldSet.new(:component,[:id,:display_name,:attributes])
      # TODO: allowing feature in until nest features in base services filter = [:and, [:eq, :component__id, component_id],[:eq, :basic_type,"service"]]
      filter = [:and, [:eq, :component__id, component_id]]
      global_wc = {attribute__semantic_type_summary: "sap_config__l4"}
      ds = SearchObject.create_from_field_set(field_set,cmp_id_handle[:c],filter).create_dataset().where(global_wc)

      # should only be one attribute matching (or none)
      component = ds.all.first
      sap_config_attr = (component||{})[:attribute]
      return nil unless sap_config_attr
      sap_config_attr_idh = cmp_id_handle.createIDH(guid: sap_config_attr[:id],model_name: :attribute, parent_model_name: :component)

      # cartesian product of sap_config(s) and host addreses
      new_sap_value_list = []
      # TODO: if graph converted hased values into Model types then could just do sap_config_attr[:attribute_value]
      values = sap_config_attr[:value_asserted]||sap_config_attr[:value_derived]
      # values can be hash or array; determine by looking at semantic_type
      # TODO: may use instead look up from semantic type
      values = [values] unless values.is_a?(Array)
      values.each do |sap_config|
        ipv4_host_addresses.each do |ipv4_addr|
          new_sap_value_list << sap_config.merge(host_address: ipv4_addr)
        end
      end

      description_prefix = (component[:display_name]||"").split("::").map{|x|x.capitalize}.join(" ") 
      description = description_prefix.empty? ? "Service Access Point" : "#{description_prefix} SAP"

      new_sap_attr_rows =
        [{
           ref: "sap__l4",
           display_name: "sap__l4", 
           component_component_id: component_id,
           value_derived: new_sap_value_list,
           is_port: true,
           hidden: true,
           data_type: "json",
           description: description,
           # TODO: need the  => {"application" => service qualification)
           semantic_type: {":array" => "sap__l4"},
           semantic_type_summary: "sap__l4"
         }]

      attr_mh = sap_config_attr_idh.createMH()
      new_sap_attr_idh = create_from_rows(attr_mh,new_sap_attr_rows, convert: true).first
      
      [sap_config_attr_idh,new_sap_attr_idh]
    end

    ###################################################################
    ##TODO: need to go over each one below to see what we still should use

    def check_and_set_derived_relation!
      ingress_objects = Model.get_objects(ModelHandle.new(id_handle[:c],:attribute_link),output_id: self[:id])
      return nil if ingress_objects.nil?
      ingress_objects.each do |input_obj|
        fn = AttributeLink::ret_function_if_can_determine(input_obj,self)
        check_and_set_derived_rel_from_link_fn!(fn)
      end
    end

    # sets this attribute derived relation from fn given as input; if error throws trap
    # TBD: may want to pass in more context about input so that can set fn
    def check_and_set_derived_rel_from_link_fn!(fn)
      return nil if fn.nil?
      if self[:function].nil?
        update(function: fn)
        return nil
      end
      raise Error.new("mismatched link") 
    end

    ### virtual column defs
    # returns asserted first then derived

    def unknown_in_attribute_value
      attr_value = attribute_value()
      return true if attr_value.nil?
      return nil unless self[:is_array]
      return nil unless attr_value.is_a?(Array) #TBD: this should be error      
      attr_value.each{|v| return true if v.nil?}
      return nil
    end

    def assoc_components_on_nodes
      parent_obj = get_parent_object()	
      return [] if parent_obj.nil?
      case parent_obj.relation_type
        when :node
          []
        when :component
          parent_obj.get_objects_associated_nodes().map do |n|
            {node: n, component: parent_obj}
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
       # TBD: stub; ignores config constraints on sap_config
       return nil if ip_addr.nil? || sap_config.nil?
       port = sap_config[:network] ? sap_config[:network][:port] : nil
       return nil if port.nil?
       {
          network: {
            port: port,
            addresses: [ip_addr]
          }
       }
      end
      
      def sap_ref_from_sap(sap)
        return nil if sap.nil?
        # TBD: stubbed to only handle limited cases
        raise Error::NotImplemented.new("sap to sap ref function where not type 'network'") unless sap[:network]
        raise Error.new("network sap missing port number") unless sap[:network][:port]
        raise Error.new("network sap missing addresses") unless sap[:network][:addresses]
        raise Error::NotImplemented.new("saps with multiple IP addresses") unless sap[:network][:addresses].size == 1
        {network: {
           port: sap[:network][:port],
           address: sap[:network][:addresses][0]
          }
        }
      end
    end
  end
end
