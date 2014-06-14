module DTK
  class Node < Model
    r8_nested_require('node','meta')

    set_relation_name(:node,:node)

    r8_nested_require('node','type')
    r8_nested_require('node','template')
    r8_nested_require('node','instance')
    r8_nested_require('node','target_ref')
    r8_nested_require('node','filter')
    r8_nested_require('node','clone')
    r8_nested_require('node','attribute')

    include TypeMixin
    include CloneMixin
    extend NodeMetaClassMixin 
    extend AttributeClassMixin
    include AttributeMixin

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
       :managed,
       :admin_op_status
      ]
    end

#TODO: stub for feature_node_admin_state
    def persistent_hostname?()
#      true
      false
    end


#TODO: end stub for feature_node_admin_state

    ### virtual column defs
    #######################
    #TODO: write as sql fn for efficiency
    def has_pending_change()
      ((get_field?(:action)||{})[:count]||0) > 0
    end

    def status()
      #assumes :is_deployed and :operational_status are set
      (not self[:is_deployed]) ? Type::Node.staged : self[:operational_status]
    end

    def target_id()
      get_field?(:datacenter_datacenter_id)
    end

    def name()
      get_field?(:display_name)
    end

    def pp_name_and_id(opts={})
      first_word = (opts[:capitalize] ? 'Node' : 'node')
      "#{first_word} (#{name()}) with id (#{id.to_s})"
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

    def get_aug_node_with_dns_info()
      #TODO: relying on the keys below being unique; more robust would be to check againts existing names
      #TODO: to supporting this may want to put in logic that prevents assemblies with explicit names from having same name
      sp_hash = {
        :cols => [:r8_dns_info,:id,:group_id,:display_name,:ref,:ref_num]
      }
      #checking for multiple rows to handle case where multiple dns attributes given
      aug_nodes = get_objs(sp_hash,:keep_ref_cols => true)
      aug_nodes.sort do |a,b|
        DNS.attr_rank(a[:attribute_r8_dns_enabled]) <=> DNS.attr_rank(b[:attribute_r8_dns_enabled])
      end.first
    end

    module DNS
      def self.attr_rank(attr)
        ret = LowestRank
        if attr_name = (attr||{})[:display_name]
          if rank = RankPos[attr_name]
            ret = rank
          end
        end
        ret
      end
      #Assumes that AttributeKeys has been defined already
      RankPos = AttributeKeys.inject(Hash.new) {|h,ak|
        h.merge(ak => AttributeKeys.index(ak))
      }
      LowestRank = AttributeKeys.size
    end

    def self.get_violations(id_handles)
      get_objs_in_set(id_handles,{:cols => [:violations]}).map{|r|r[:violation]}
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

    def get_assembly?(cols=nil)
      if assembly_id = get_field?(:assembly_id)
        sp_hash = {
        :cols => cols||[:id,:group_id,:display_name],
          :filter => [:eq,:id,assembly_id]
        }
        Assembly::Instance.get_objs(model_handle(:assembly_instance),sp_hash).first
      end
    end

    def self.list(model_handle,opts={})
      target_filter = (opts[:target_idh] ? [:eq,:datacenter_datacenter_id,opts[:target_idh].get_id()] : [:neq,:datacenter_datacenter_id,nil])
      filter = [:and, [:oneof, :type, [Type::Node.instance,Type::Node.staged,"physical"]], target_filter]
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
      filter = [:and, [:oneof, :type, [Type::Node.instance,Type::Node.staged]], [:eq, :assembly_id, nil]]
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

    def self.legal_display_name?(display_name)
      display_name =~ LegalDisplayName
    end
    LegalDisplayName = /^[a-zA-Z0-9_\[\]\.-]+$/

    def self.user_friendly_name(node_name,assembly_name=nil)
      assembly_name ? "#{assembly_name}::#{node_name}" : node_name
    end
    private_class_method :user_friendly_name

    #returns [node_name, assembly_name] later which could be nil
    def self.parse_user_friendly_name(name)
      node_name = assembly_name = nil
      if name =~ Regexp.new("(^.+)#{AssemblyNodeNameSep}(.+$)")
        node_name,assembly_name = [$2,$1]
      else
        node_name = name
      end
      unless legal_display_name?(node_name)
        raise ErrorNameInvalid.new(node_name,:node)
      end
      [node_name,assembly_name]
    end
    private_class_method :parse_user_friendly_name
    AssemblyNodeNameSep = '::'
    
    def info(opts={})
      ret = get_obj(:cols => InfoCols).hash_subset(*InfoCols)
      opts[:print_form] ? info_print_form_processing!(ret) : ret
    end
    InfoCols = [:id,:display_name,:os_type,:type,:description,:status,:external_ref,:assembly_id]

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

    def self.sanitize!(node)
      if external_ref = node[:external_ref]
        external_ref.delete(:ssh_credentials)
      end
    end
    def sanitize!()
      self.class.sanitize!(self)
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

    def add_component(component_template,component_title=nil)
      component_template.update_with_clone_info!()
      override_attrs = {:locked_sha => component_template.get_current_sha!()}
      if title_attr_name = check_and_ret_title_attribute_name?(component_template,component_title)
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
        Component::Instance.set_title_attribute(new_cmp_idh,component_title,title_attr_name)
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

    def self.check_valid_id(model_handle,id,assembly_id=nil)
      filter = 
        [:and,
         [:eq, :id, id],
         [:oneof, :type, [Type::Node.instance,Type::Node.staged]],
         [:neq, :datacenter_datacenter_id, nil],
         assembly_id && [:eq, :assembly_id, assembly_id]
        ].compact
      check_valid_id_helper(model_handle,id,filter)
    end

    def self.name_to_id(model_handle,name,assembly_id=nil)
      node_name, assembly_name = parse_user_friendly_name(name)
      unless legal_display_name?(node_name)
        raise ErrorNameInvalid.new(node_name,:node)
      end
      assembly_id ||= assembly_name && Assembly::Instance.name_to_id(model_handle.createMH(:component),assembly_name)
      sp_hash =  {
        :cols => [:id,:assembly_id],
        :filter => [:and,
                    [:eq, :display_name, node_name],
                    [:oneof, :type, [Type::Node.instance,Type::Node.staged]],
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
        return  Type::Node.staged if not self[:is_deployed]
      end
      update_obj!(:is_deployed,:external_ref,:operational_status)
      return  Type::Node.staged if not self[:is_deployed]
      get_and_update_operational_status!()
    end

    def get_and_update_operational_status!()
      update_obj!(:external_ref,:operational_status)
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

    def get_external_ref()
      get_field?(:external_ref)||{}
    end

    def get_iaas_type()
      ret = get_external_ref()[:type]
      ret && ret.to_sym
    end

    def instance_id()
      get_external_ref()[:instance_id]
    end

    def pbuilderid()
      self.class.pbuilderid(self)
    end
    def self.pbuilderid(node)
      unless ret = CommandAndControl.pbuilderid(node)
        raise Error.new("Node (#{node.get_field?(:display_name)}) with id (#{node.id.to_s}) does not have an #{PBuilderIDPrintName}")
      end
      ret
    end
    PBuilderIDPrintName = 'internal communication ID'

    def persistent_dns()
      get_hostname_external_ref()[:persistent_dns]
    end

    def elastic_ip()
      get_hostname_external_ref()[:elastic_ip]
    end

    def get_hostname_external_ref()
      get_field?(:hostname_external_ref)||{}
    end
    private :get_hostname_external_ref


#TODO: these may be depracted
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
#end of these may be depracted

    
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


    #### end: related to distinguishing bewteen nodes and node groups

    def destroy_and_delete(opts={})
      if suceeeded = CommandAndControl.destroy_node?(self)
        delete_object(opts)
      end
      suceeeded
    end

    def destroy_and_reset(target_idh)
      if CommandAndControl.destroy_node?(self,:reset => true)
        StateChange.create_pending_change_item(:new_item => id_handle(), :parent => target_idh)
      end
    end

    def delete_object(opts={})
      update_dangling_links()
      if opts[:update_task_template]
        unless assembly = opts[:assembly]
          raise Error.new("If update_task_template is assembled :assembly must be given as an option")
        end
        update_task_templates_when_deleted_node?(assembly)
      end
      Model.delete_instance(id_handle())
      true
    end

    def update_task_templates_when_deleted_node?(assembly)
      #TODO: can be more efficient if have Task::Template method that takes node and deletes all teh nodes component in bulk
      sp_hash = {
        #:only_one_per_node,:ref are put in for info needed when getting title
        :cols => [:id, :display_name, :node_node_id,:only_one_per_node,:ref],
        :filter => [:eq, :node_node_id, id()]
      }
      components = Component::Instance.get_objs(model_handle(:component),sp_hash)
      components.map{|cmp|Task::Template::ConfigComponents.update_when_deleted_component?(assembly,self,cmp)}
    end
    private :update_task_templates_when_deleted_node?

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
      attr_mh = model_handle_with_auth_info(:attribute)
      #update attributes connected to dangling links on input side
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

#TODO: should this be more generic and centralized?
    def get_objects_associated_components()
      assocs = Model.get_objects(ModelHandle.new(@c,:assoc_node_component),:node_id => self[:id])
      return [] if assocs.nil?
      assocs.map{|assoc|Model.get_object(IDHandle[:c=>@c,:guid => assoc[:component_id]])}
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



