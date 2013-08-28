r8_nested_require('node','meta')
module XYZ
  class Node < Model
    set_relation_name(:node,:node)

    r8_nested_require('node','template')
    r8_nested_require('node','filter')
    r8_nested_require('node','clone')

    include CloneMixin
    extend NodeMetaClassMixin 

    def self.common_columns()
      [
       :id,
       :group_id,
       :display_name,
       :name,
       :os_type,
       :type,
       :description,
       :status,
       :target_id,
       :ui,
       :external_ref,
       :admin_op_status
      ]
    end
#TODO: stub for feature_node_admin_state
    def persistent_hostname?()
#      true
      false
    end

    class Instance < self
     def self.component_list_fields()
       [:id,:display_name,:group_id,:external_ref,:ordered_component_ids]
     end

      def self.get(mh,opts={})
        sp_hash = {
          :cols => ([:id,:group_id,:display_name]+(opts[:cols]||[])).uniq,
          :filter => [:neq,:datacenter_datacenter_id,nil]
        }
        get_objs(mh,sp_hash)
      end

      def self.get_unique_instance_name(mh,display_name)
        display_name_regexp = Regexp.new("^#{display_name}")
        matches = get(mh,:cols=>[:display_name]).select{|r|r[:display_name] =~ display_name_regexp}
        if matches.empty?
          return display_name
        end
        index = 2
        matches.each do |r|
          instance_name = r[:display_name]
          if instance_name =~ /-([0-9]+$)/
            instance_index = $1.to_i
            if instance_index >= index
              index += 1
            end
          end
        end
        "#{display_name}-#{index.to_s}"
      end
    end


#TODO: end stub for feature_node_admin_state

    ### virtual column defs
    #######################
    #TODO: write as sql fn for efficiency
    def has_pending_change()
      update_object!(:action)
      ((self[:action]||{})[:count]||0) > 0
    end

    def status()
      #assumes :is_deployed and :operational_status are set
      (not self[:is_deployed]) ? "staged" : self[:operational_status]
    end

    def target_id()
      update_object!(:datacenter_datacenter_id)[:datacenter_datacenter_id]
    end

    def name()
      update_object!(:display_name)[:display_name]
    end

    #######################
    # standard get methods
    def get_target(additional_columns = [])
      sp_hash = {
        :cols => [:id,:group_id,:display_name] + additional_columns,
        :filter => [:eq,:id,target_id()]
      }
      target = Model.get_obj(model_handle(:target),sp_hash)

      return target
    end

    def get_target_iaas_type()
      get_target().get_iaas_type()
    end

    def get_target_iaas_credentials()
      # TODO: Haris - When we support multiple IAAS we will need to modify logic here
      get_target().get_aws_compute_params()
    end

    def self.get_violations(id_handles)
      get_objs_in_set(id_handles,{:cols => [:violations]}).map{|r|r[:violation]}
    end

    def self.get_node_level_attributes(node_idhs,cols=nil,add_filter=nil)
      ret = Array.new
      return ret if node_idhs.empty?()
      filter = [:oneof,:node_node_id,node_idhs.map{|idh|idh.get_id()}]
      if add_filter
        filter = [:and,filter,add_filter]
      end
      sp_hash = {
        :cols => cols||[:id,:group_id,:display_name,:required],
        :filter => filter,
      }
      attr_mh = node_idhs.first.createMH(:attribute)
      get_objs(attr_mh,sp_hash)
    end

    def get_project()
      get_objects_col_from_sp_hash(:cols => [:project]).first
    end

    def self.get_ports(id_handles)
      get_objs_in_set(id_handles,{:cols => [:ports]},{:keep_ref_cols => true}).map{|r|r[:port]}
    end

    def get_ports(*types)
      port_list = self.class.get_ports([id_handle])
      i18n = get_i18n_mappings_for_models(:component,:attribute)
      port_list.map{|port|port.filter_and_process!(i18n,*types)}.compact
    end

    ######### Model apis


    def self.list(model_handle,opts={})
      target_filter = (opts[:target_idh] ? [:eq,:datacenter_datacenter_id,opts[:target_idh].get_id()] : [:neq,:datacenter_datacenter_id,nil])
      filter = [:and, [:oneof, :type, ["instance","staged"]], target_filter]
      sp_hash = {
        :cols => common_columns() + [:assemblies],
        :filter => filter
      }
      cols_except_name = common_columns() - [:display_name]
      get_objs(model_handle,sp_hash).map do |n|
        el = n.hash_subset(*cols_except_name)
        assembly_name = (n[:assembly]||{})[:display_name]
        el.merge(:display_name => user_friendly_name(n[:display_name],assembly_name))
      end.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    def self.list_wo_assembly_nodes(model_handle)
      filter = [:and, [:oneof, :type, ["instance","staged"]], [:eq, :assembly_id, nil]]
      sp_hash = {
        :cols => common_columns() + [:assemblies],
        :filter => filter
      }
      cols_except_name = common_columns() - [:display_name]
      get_objs(model_handle,sp_hash).map do |n|
        el = n.hash_subset(*cols_except_name)
        assembly_name = (n[:assembly]||{})[:display_name]
        el.merge(:display_name => user_friendly_name(n[:display_name],assembly_name))
      end.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    class << self
     private
      def user_friendly_name(node_name,assembly_name=nil)
        assembly_name ? "#{assembly_name}::#{node_name}" : node_name
      end
      #returns [node_name, assembly_name] later which coudl be null
      def parse_user_friendly_name(name)
        if name =~ Regexp.new("(^.+)#{AssemblyNodeNameSep}(.+$)")
          [$2,$1]
        else
          name
        end
      end
      AssemblyNodeNameSep = '::'
    end
    InfoCols = [:id,:display_name,:os_type,:type,:description,:status,:external_ref,:assembly_id]

    def info(opts={})
      ret = get_obj(:cols => InfoCols).hash_subset(*InfoCols)
      opts[:print_form] ? info_print_form_processing!(ret) : ret
    end

    def info_print_form_processing!(info_hash)
      if external_ref = info_hash[:external_ref]
        private_dns = external_ref[:private_dns_name]
        if private_dns.kind_of?(Hash)
          #then :private_dns_name is of form <public dns> => <private dns>
          external_ref[:private_dns_name] = private_dns.values.first 
        end
      end
      info_hash
    end

    
    def info_about(about,opts={})
      case about
       when :components
        get_objs(:cols => [:components],:keep_ref_cols => true).map do |r|
          r[:component].convert_to_print_form!()
        end.sort{|a,b|a[:display_name] <=> b[:display_name]}
       when :attributes
        get_attributes_print_form()
       else
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")        
      end
    end

    def find_violations()
      cmps = get_objs(:cols => [:components],:keep_ref_cols => true)
      
      ret = Array.new
      return ret if cmps.empty?
      
      cmps.each do |cmp|
        sp_hash = {
          :cols => [:id, :type, :component_id, :service_id],
          :filter => [:eq, :id, cmp[:component][:module_branch_id]]
        }
        branch = Model.get_obj(model_handle(:module_branch),sp_hash)

        sp_cmp_hash = {
          :cols => [:id, :display_name, :dsl_parsed],
          :filter => [:eq, :id, branch[:component_id]]
        }
        cmp_module = Model.get_obj(model_handle(:component_module),sp_cmp_hash)
        
        ret << NodeViolations::NodeComponentParsingError.new(cmp_module[:display_name], "Component") unless cmp_module[:dsl_parsed]
      end

      ret
    end

    def get_attributes_print_form(opts={})
      if filter = opts[:filter]
        case filter
          when :required_unset_attributes
            get_attributes_print_form_aux(lambda{|a|a.required_unset_attribute?()})
          else 
            raise Error.new("not treating filter (#{filter}) in Assembly::Instance#get_attributes_print_form")
        end  
      else
        get_attributes_print_form_aux()
      end
    end

    def get_node_attributes()
      Array.new #TODO: stub
    end

    def get_node_and_component_attributes(opts={})
      node_attrs = get_node_attributes()
      component_attrs = get_objs(:cols => [:components_and_attrs]).map{|r|r[:attribute]}
      component_attrs + node_attrs
    end
    def get_attributes_print_form_aux(filter_proc=nil)
      node_attrs = get_node_attributes()
      component_attrs = get_objs(:cols => [:components_and_attrs]).map do |r|
        attr = r[:attribute]
       #TODO: more efficient to have sql query do filtering
        if filter_proc.nil? or filter_proc.call(attr)
          display_name_prefix = "#{r[:component].display_name_print_form()}/"
          attr.print_form(Opts.new(:display_name_prefix => display_name_prefix))
        end
      end.compact
      (component_attrs + node_attrs).sort{|a,b|a[:display_name] <=> b[:display_name]}
    end
    private :get_attributes_print_form_aux


    def set_attributes(av_pairs)
      Attribute::Pattern::Node.set_attributes(self,av_pairs)
    end

    def add_component(component_template,component_title=nil)
      title_attr_name = check_and_ret_title_attribute_name?(component_template,component_title)
      override_attrs = Hash.new
      if title_attr_name
        component_type = component_template.get_field?(:component_type)
        override_attrs = {
          :ref => SQL::ColRef.cast(ComponentTitle.ref_with_title(component_type,component_title),:text),
          :display_name => SQL::ColRef.cast(ComponentTitle.display_name_with_title(component_type,component_title),:text)
        }
      end
      clone_opts = {:no_post_copy_hook => true,:ret_new_obj_with_cols => [:id,:display_name]}
      new_cmp = clone_into(component_template,override_attrs,clone_opts)
      new_cmp_idh = new_cmp.id_handle()
      if title_attr_name
        Component::Instance.set_title(new_cmp_idh,component_title,title_attr_name)
      end
      new_cmp_idh
    end

    def delete_component(component_idh)
      #first check that component_idh belongs to this instance
      sp_hash = {
        :cols => [:id, :display_name],
        :filter => [:and, [:eq, :id, component_idh.get_id()], [:eq, :node_node_id, id()]]
      }
      unless Model.get_obj(model_handle(:component),sp_hash)
        raise ErrorIdInvalid.new(component_idh.get_id(),:component)
      end
      Model.delete_instance(component_idh)
    end

    def check_and_ret_title_attribute_name?(component_template,component_title)
      title_attr_name = component_template.get_title_attribute_name?()
      if component_title and title_attr_name.nil?
        raise ErrorUsage.new("Component (#{component_template.component_type_print_form()}) given a title but should not have one")
      elsif component_title.nil? and title_attr_name
        raise ErrorUsage.new("Component (#{component_template.component_type_print_form()}) needs a title, but not given one")
      end 

      if title_attr_name
        component_type = component_template.get_field?(:component_type)
        if matching_component_instance_exists?(component_type,title_attr_name)
          raise ErrorUsage.new("Component (#{component_template.component_type_print_form()}) already exists with title (#{component_title})")
        end
      end

      title_attr_name
    end
    private :check_and_ret_title_attribute_name?

    def matching_component_instance_exists?(component_type,title_attr_name)
      sp_hash = {
        :cols => [:id],
        :filter => [:and,[:eq,:node_node_id,id()],[:eq,:component_type,component_type]]
      }
      cmps = Model.get_objs(model_handle(:component),sp_hash)
      unless cmps.empty?
        sp_hash = {
          :cols => [:id],
          :filter => [:and,[:oneof,:component_component_id,cmps.map{|cmp|cmp[:id]}],
                       [:eq,:display_name,title_attr_name]]
        }
        not Model.get_obj(model_handle(:attribute),sp_hash).nil?
      end
    end
    private :matching_component_instance_exists?


    def self.check_valid_id(model_handle,id)
      filter = 
        [:and,
         [:eq, :id, id],
         [:oneof, :type, ["instance","staged"]],
         [:neq, :datacenter_datacenter_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end

    def self.name_to_id(model_handle,name)
      node_name, assembly_name = parse_user_friendly_name(name)
      assembly_id = assembly_name && Assembly::Instance.name_to_id(model_handle.createMH(:component),assembly_name)
      sp_hash =  {
        :cols => [:id,:assembly_id],
        :filter => [:and,
                    [:eq, :display_name, node_name],
                    [:oneof, :type, ["instance","staged"]],
                    [:neq, :datacenter_datacenter_id, nil],
                    [:eq, :assembly_id, assembly_id]]
      }
      name_to_id_helper(model_handle,name,sp_hash)
    end

    def update_external_ref_field(ext_ref_field,val)
      update({:external_ref => {ext_ref_field => val}},{:partial_value=>true})
    end

    def get_and_update_status!()
      #shortcut
      if has_key?(:is_deployed)
        return  "staged" if not self[:is_deployed]
      end
      update_object!(:is_deployed,:external_ref,:operational_status)
      return  "staged" if not self[:is_deployed]
      get_and_update_operational_status!()
    end

    def get_and_update_operational_status!()
      update_object!(:external_ref,:operational_status)
      op_status = CommandAndControl.get_node_operational_status(self)
      if op_status
        unless self[:operational_status] == op_status
          update_operational_status!(op_status)
        end
      end
      op_status || self[:operational_status]
    end

    def is_node_group?()
      ["node_group_instance"].include?(self[:type])
    end

    #attribute on node
    def update_operational_status!(op_status)
      update(:operational_status => op_status.to_s)
      self[:operational_status] = op_status.to_s
    end

    def update_admin_op_status!(op_status)
      update(:admin_op_status => op_status.to_s)
      self[:admin_op_status] = op_status.to_s
    end

    def update_agent_git_commit_id(agent_git_commit_id)
      update(:agent_git_commit_id => agent_git_commit_id)
      self[:agent_git_commit_id] = agent_git_commit_id      
    end

    def update_ordered_component_ids(order)
      ordered_component_ids = "{ :order => [#{order.join(',')}] }"
      update(:ordered_component_ids => ordered_component_ids)
      self[:ordered_component_ids] = ordered_component_ids      
    end

    def get_ordered_component_ids()
      ordered_component_ids = self[:ordered_component_ids]
      return Array.new unless ordered_component_ids
      eval(ordered_component_ids)[:order]
    end

    def self.pbuilderid(node)
      node.update_object!(:external_ref)
      (node[:external_ref]||{})[:instance_id]
    end
    def pbuilderid()
      Node.pbuilderid(self)
    end

    def instance_id()
      update_object!(:external_ref)
      (self[:external_ref]||{})[:instance_id]
    end

    def persistent_dns()
      update_object!(:hostname_external_ref)
      (self[:hostname_external_ref]||{})[:persistent_dns]
    end

    def elastic_ip()
      update_object!(:hostname_external_ref)
      (self[:hostname_external_ref]||{})[:elastic_ip]
    end
    
    def get_virtual_attribute(attribute_name,cols,field_to_match=:display_name)
      sp_hash = {
        :model_name => :attribute,
        :filter => [:eq, field_to_match, attribute_name],
        :cols => cols
      }
      get_children_from_sp_hash(:attribute,sp_hash).first
    end
    #TODO: may write above in terms of below
    def get_virtual_attributes(attribute_names,cols,field_to_match=:display_name)
      sp_hash = {
        :model_name => :attribute,
        :filter => [:oneof, field_to_match, attribute_names],
        :cols => Aux.array_add?(cols,field_to_match)
      }
      get_children_from_sp_hash(:attribute,sp_hash)
    end

    def self.get_virtual_attributes(attrs_to_get,cols,field_to_match=:display_name)
      ret = Hash.new
      #TODO: may be able to avoid this loop
      attrs_to_get.each do |node_id,hash_value|
        attr_info = hash_value[:attribute_info]
        node = hash_value[:node]
        attr_names = attr_info.map{|a|a[:attribute_name].to_s}
        rows = node.get_virtual_attributes(attr_names,cols,field_to_match)
        rows.each do |attr|
          attr_name = attr[field_to_match]
          ret[node_id] ||= Hash.new
          ret[node_id][attr_name] = attr
        end
      end
      ret
    end

    #### related to distinguishing bewteen nodes and node groups

    def self.get_node_or_ng_summary(node_mh,node_ids)
      ret = Hash.new
      return ret if node_ids.empty?
      sp_hash = {
        :cols => [:id,:type,:node_or_ng_summary],
        :filter => [:oneof, :id, node_ids]
      }
      get_objs(node_mh,sp_hash).inject({}) do |ret,n|
        n.delete(:node_group_relation)
        node_member = n.delete(:node_member)
        node_id = n[:id]
        if n.is_node_group?()
          pntr = ret[node_id] ||= NodeGroup.create_as(n).merge(:node_group_members => Array.new)
          pntr[:node_group_members] << node_member if node_member
          ret
        else
          ret.merge(node_id => n)
        end
      end
    end

    def is_node?()
      update_object!(:type)
       NodeTypes.include?(self[:type])
    end
    def is_node_group?()
      #short circuit
      return true if kind_of?(NodeGroup)
      update_object!(:type)
      NodeGroupTypes.include?(self[:type])
    end
    NodeTypes = %w{instance image staged}
    NodeGroupTypes = %w{node_group_instance}

    #### end: related to distinguishing bewteen nodes and node groups


    #attribute on component on node
    #assumption is that component cannot appear more than once on node
    def get_virtual_component_attribute(cmp_assign,attr_assign,cols)
      base_sp_hash = {
        :model_name => :component,
        :filter => [:and, [:eq, cmp_assign.keys.first,cmp_assign.values.first],[:eq, :node_node_id,self[:id]]],
        :cols => [:id]
        }
      join_array = 
        [{
           :model_name => :attribute,
           :convert => true,
           :join_type => :inner,
           :filter => [:eq, attr_assign.keys.first,attr_assign.values.first],
           :join_cond => {:component_component_id => :component__id},
           :cols => cols.include?(:component_component_id) ? cols : cols + [:component_component_id]
         }]
      row = Model.get_objects_from_join_array(model_handle.createMH(:component),base_sp_hash,join_array).first
      row && row[:attribute]
    end

    def delete_object()
      update_dangling_links()
      Model.delete_instance(id_handle())
    end
    def destroy_and_delete()
      update_object!(:external_ref,:hostname_external_ref)
      suceeeded = CommandAndControl.destroy_node?(self)
      delete_object() if suceeeded
    end

    def update_dangling_links()
      dangling_links_info_cmps = get_objs(:cols => [:dangling_input_links_from_components])
      dangling_links_info_nodes = get_objs(:cols => [:dangling_input_links_from_nodes])

      #TODO: if only processing external links, more efficeint to filter in sql query
      ndx_dangling_links_info = Hash.new
      (dangling_links_info_cmps + dangling_links_info_nodes).each do |r|
        link = r[:all_input_links]
        if link[:type] == "external"
          attr_id = link[:input_id]
          p = ndx_dangling_links_info[attr_id] ||= {:input_attribute => r[:input_attribute], :other_links => Array.new}
          new_el = {
            :attribute_link_id => link[:id], 
            :index_map => link[:index_map], 
          }
          if link[:id] == r[:attribute_link][:id]
            p[:deleted_link] = new_el
          else
            p[:other_links] << new_el
          end
        end
      end
      attr_mh = model_handle(:attribute)
      #update attribles connected to dangling links on input side
      updated_attrs = AttributeUpdateDerivedValues.update_for_delete_links(attr_mh,ndx_dangling_links_info.values)
      #add state changes for updated attributes and see if any connected attributes
      Attribute.propagate_and_optionally_add_state_changes(attr_mh,updated_attrs,:add_state_changes => true)
    end
    private :update_dangling_links


    def self.get_port_links(id_handles,*port_types)
      input_port_rows =  get_objs_in_set(id_handles,:columns => [:id, :display_name, :input_port_link_info]).select do |r|
        port_types.include?((r[:port]||{})[:type])
      end
      #TODO: implement using PortLink.common_columns and materialize
      input_port_rows.each do |r|
        r[:port_link][:ui] ||= {
          :type => R8::Config[:links][:default_type],
          :style => R8::Config[:links][:default_style]
        }
      end
      
      output_port_rows =  get_objs_in_set(id_handles,:columns => [:id, :display_name, :output_port_link_info]).select do |r|
        port_types.include?((r[:port]||{})[:type])
      end
      #TODO: implement using PortLink.common_columns and materialize
      output_port_rows.each do |r|
        r[:port_link][:ui] ||= {
          :type => R8::Config[:links][:default_type],
          :style => R8::Config[:links][:default_style]
        }
      end

      return Array.new if input_port_rows.empty? and output_port_rows.empty?

      indexed_ret = Hash.new
      input_port_rows.each do |r|
        id = r[:id]
        indexed_ret[id] ||= r.subset(:id, :display_name).merge(:input_port_links => Array.new, :output_port_links => Array.new)
        indexed_ret[id][:input_port_links] << r[:port_link]
      end
      output_port_rows.each do |r|
        id = r[:id]
        indexed_ret[id] ||= r.subset(:id, :display_name).merge(:output_port_links => Array.new, :output_port_links => Array.new)
        indexed_ret[id][:output_port_links] << r[:port_link]
      end
      indexed_ret.values
    end

    def self.get_output_attrs_to_l4_input_ports(id_handles)
      rows = get_objs_in_set(id_handles,{:cols => [:output_attrs_to_l4_input_ports]},{:keep_ref_cols => true})
      return Hash.new if rows.empty?
      #restructure so that get mapping from attribute_id to port
      ret = Hash.new
      rows.each do |row|
        attr_id = row[:port_external_output][:external_attribute_id]
        ret[attr_id] ||= Array.new
        ret[attr_id] << row[:port_l4_input]
      end
      ret
    end

    def get_ui_info(datacenter)
      datacenter_id_sym = datacenter[:id].to_s.to_sym
      node_id_sym = self[:id].to_s.to_sym
      #TODO: hack assumes that canm just take position from first node[:u1]
      ((datacenter[:ui]||{})[:items]||{})[node_id_sym] || (self[:ui]||{})[datacenter_id_sym] || (self[:ui]||{}).values.first
    end

    def update_ui_info!(ui,datacenter)
      datacenter_id_sym = datacenter[:id].to_s.to_sym
      node_id_sym = self[:id].to_s.to_sym
      self[:ui] ||= Hash.new
      self[:ui][datacenter_id_sym] = ui
    end

    def get_users()
      node_user_list = get_objects_from_sp_hash(:columns => [:users])
      user_list = Array.new
      #TODO: just putting in username, not uid or gid
      node_user_list.map do |u|
        attr = u[:attribute]
        val = attr[:value_asserted]||attr[:value_derived]
        (val and attr[:display_name] == "username") ? {:id => attr[:id], :username => val, :avatar_filename => 'generic-user-male.png'} : nil 
      end.compact
    end

    def get_applications()
      app_hash_list = get_objects_col_from_sp_hash({:columns => [:applications]},:component)

      i18n = get_i18n_mappings_for_models(:component)
      app_hash_list.map do |component|
        name = component[:display_name]
        cmp_i18n = i18n_string(i18n,:component,name)
        component_el = {:id => component[:id], :name =>  name, :i18n => cmp_i18n}
        component_icon_fn = ((component[:ui]||{})[:images]||{})[:tnail]
        component_el.merge(component_icon_fn ? {:component_icon_filename => component_icon_fn} : {})
      end
    end

    # Method will take already allocated elastic IP and assign it deploy node.
    # Keep in mind this can only happen when node is 'running' state
    def associate_elastic_ip?()
      if persistent_hostname?
        CommandAndControl.associate_elastic_ip(self)
      end
    end

    def associate_persistent_dns?()
        CommandAndControl.associate_persistent_dns?(self)
    end

    # Method will remove DNS information for node, this happens when we do not persistent
    # DNS and by stopping node we do not need to keep DNS information
    def strip_dns_info!()
      self.update(:external_ref => self[:external_ref].merge(:dns_name => nil, :ec2_public_address => nil, :private_dns_name => nil ))
    end

    def get_node_service_checks()
      return Array.new if get_objects_from_sp_hash(:columns => [:monitoring_agents]).empty?

      #TODO: i18n treatment of service check names
      get_objects_col_from_sp_hash({:columns => [:monitoring_items__node]},:monitoring_item)
    end
    def get_component_service_checks()
      return Array.new if get_objects_from_sp_hash(:columns => [:monitoring_agents]).empty?
      #TODO: i18n treatment of service check names
      i18n = get_i18n_mappings_for_models(:component)

      get_objects_from_sp_hash(:columns => [:monitoring_items__component]).map do |r|
        cmp_name = r[:component][:display_name]
        cmp_info = {:component_name => cmp_name,:component_i18n => i18n_string(i18n,:component,cmp_name) }
        r[:monitoring_item].merge(cmp_info)
      end
    end

    #returns external attribute links and port links
    #returns [connected_links,dangling_links]
    def self.get_external_connected_links(id_handles)
      port_link_ret = get_conn_port_links(id_handles)
      attr_link_ret = get_conn_external_attr_links(id_handles)
      [port_link_ret[0]+attr_link_ret[0],port_link_ret[1]+attr_link_ret[1]]
    end

    #return ports links 
    #returns [connected_links,dangling_links]
    def self.get_conn_port_links(id_handles,opts={})
      ret = [Array.new,Array.new]
      in_port_cols = [:id, :display_name, :input_port_links]
      ndx_in_links = Hash.new
      get_objs_in_set(id_handles,{:columns => in_port_cols}).each do |r|
        link = r[:port_link]
        ndx_in_links[link[:id]] = link 
      end

      out_port_cols = [:id, :display_name, :output_port_links]
      ndx_out_links = Hash.new
      get_objs_in_set(id_handles,{:columns => out_port_cols}).each do |r|
        link = r[:port_link]
        ndx_out_links[link[:id]] = link 
      end

      return ret if ndx_in_links.empty? and ndx_out_links.empty?

      connected_links = (ndx_in_links.keys & ndx_out_links.keys).map{|id|ndx_in_links[id]}

      dangling_links = (ndx_in_links.keys - ndx_out_links.keys).map{|id|ndx_in_links[id]}
      dangling_links += (ndx_out_links.keys - ndx_in_links.keys).map{|id|ndx_out_links[id]}
      [connected_links,dangling_links]
    end

    #return externally connected attribute links
    #returns [connected_links,dangling_links]
    def self.get_conn_external_attr_links(id_handles)
      ret = [Array.new,Array.new]

      ndx_in_links = get_objs_in_set(id_handles,:cols => [:id,:input_attribute_links_cmp]).inject({}) do |h,r|
        link = r[:attribute_link]
        link[:type] == "external" ? h.merge(link[:id] => link) : h
      end
      ndx_in_links = get_objs_in_set(id_handles,:cols => [:id,:input_attribute_links_node]).inject(ndx_in_links) do |h,r|
        link = r[:attribute_link]
        link[:type] == "external" ? h.merge(link[:id] => link) : h
      end

      ndx_out_links = get_objs_in_set(id_handles,:cols => [:id,:output_attribute_links_cmp]).inject({}) do |h,r|
        link = r[:attribute_link]
        link[:type] == "external" ? h.merge(link[:id] => link) : h
      end
      ndx_out_links = get_objs_in_set(id_handles,:cols => [:id,:output_attribute_links_node]).inject(ndx_out_links) do |h,r|
        link = r[:attribute_link]
        link[:type] == "external" ? h.merge(link[:id] => link) : h
      end

      return ret if ndx_in_links.empty? and ndx_out_links.empty?

      connected_links = (ndx_in_links.keys & ndx_out_links.keys).map{|id|ndx_in_links[id]}

      dangling_links = (ndx_in_links.keys - ndx_out_links.keys).map{|id|ndx_in_links[id]}
      dangling_links += (ndx_out_links.keys - ndx_in_links.keys).map{|id|ndx_out_links[id]}
      [connected_links,dangling_links]
    end

    #TODO: quick hack
    def self.get_wspace_display(id_handle)
      node_id = IDInfoTable.get_id_from_id_handle(id_handle)
      node_mh = id_handle.createMH(:model_name => :node)
      node = get_objects(node_mh,{:id => node_id}).first

      component_mh = node_mh.createMH(:model_name => :component)
      component_ds = get_objects_just_dataset(component_mh,{:node_node_id => node_id})
      attr_where_clause = {:is_port => true}
      #TODO: can prune what fields included
      attr_fs = Model::FieldSet.default(:attribute).with_added_cols(:component_component_id)
      attribute_mh = node_mh.createMH(:model_name => :attribute)
      attribute_ds = get_objects_just_dataset(attribute_mh,attr_where_clause,FieldSet.opt(attr_fs))
      components = component_ds.graph(:left_outer,attribute_ds,{:component_component_id => :id}).all
      node.merge(:component => components)
    end
    #######################
#TODO: may be aqble to deprecate most or all of below
      ### helpers
      def ds_attributes(attr_list)
        [:ds_attributes]
      end
      #TODO: rename subobject to sub_object
      def is_ds_subobject?(relation_type)
        false
      end


      ##### Actions
#TODO: need tp fix up below
      def self.get_node_attribute_values(id_handle,opts={})
	c = id_handle[:c]
        node_obj = get_object(id_handle,opts)
        raise Error.new("node associated with (#{id_handle}) not found") if node_obj.nil? 	
	ret = node_obj.get_direct_attribute_values(:value) || {}

	cmps = node_obj.get_objects_associated_components()
	cmps.each{|cmp|
	  ret[:component]||= {}
	  cmp_ref = cmp.get_qualified_ref.to_sym
	  ret[:component][cmp_ref] = 
	    cmp[:external_ref] ? {:external_ref => cmp[:external_ref]} : {}
	  values = cmp.get_direct_attribute_values(:value,{:attr_include => [:external_ref]})
	  ret[:component][cmp_ref][:attribute] = values if values 
        }
        ret
      end

    #######

#TODO: should this be more generic and centralized?
    def get_objects_associated_components()
      assocs = Model.get_objects(ModelHandle.new(@c,:assoc_node_component),:node_id => self[:id])
      return [] if assocs.nil?
      assocs.map{|assoc|Model.get_object(IDHandle[:c=>@c,:guid => assoc[:component_id]])}
    end

#TODO: should be centralized
    def get_contained_attribute_ids(opts={})
      get_directly_contained_object_ids(:attribute)||[]
    end

    def get_direct_attribute_values(type,opts={})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      attr_val_array = Model.get_objects(ModelHandle.new(@c,:attribute),nil,:parent_id => parent_id)
      return nil if attr_val_array.nil?
      return nil if attr_val_array.empty?
      hash_values = {}
      attr_type = {:asserted => :value_asserted, :derived => :value_derived, :value => :attribute_value}[type]
      attr_val_array.each{|attr|
        hash_values[attr.get_qualified_ref.to_sym] =
          {:value => attr[attr_type],:id => attr[:id]}
      }
      {:attribute => hash_values}
    end

    def get_obj_with_common_cols()
      common_cols =  self.class.common_columns()
      ret = get_objs(:cols => common_cols).first
      ret.materialize!(common_cols)
    end

  end
end

module XYZ
  class NodeInterface < Model
#    set_relation_name(:node,:interface)

    ### object access functions
    #######################
  end

  class NodeViolations
    class NodeComponentParsingError < self
      def initialize(component, type)
        @component = component
        @type = type
      end
      def type()
        :parsing_error
      end
      def description()
        "#{@type} '#{@component}' has syntax errors in DSL files."
      end
    end
  end
end



