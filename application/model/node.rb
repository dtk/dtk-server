module DTK
  class Node < Model
    r8_nested_require('node', 'meta')
    extend NodeMetaClassMixin
    set_relation_name(:node, :node)

    r8_nested_require('node', 'type')
    r8_nested_require('node', 'template')
    r8_nested_require('node', 'instance')
    r8_nested_require('node', 'target_ref')
    r8_nested_require('node', 'filter')
    r8_nested_require('node', 'clone')
    r8_nested_require('node', 'node_attribute')
    r8_nested_require('node', 'external_ref')
    r8_nested_require('node', 'delete')
    r8_nested_require('node', 'dangling_link_mixin')

    include Type::Mixin
    include Clone::Mixin
    extend NodeAttribute::ClassMixin
    include NodeAttribute::Mixin
    include ExternalRef::Mixin
    include Delete::Mixin
    include DanglingLink::Mixin

    def self.common_columns
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
       :hostname_external_ref,
       :managed,
       :admin_op_status
      ]
    end

    def create_obj_optional_subclass
      is_node_group?() ? create_obj_subclass() : self
    end

    def create_obj_subclass
      create_subclass_obj(node_group_model_name())
    end
    private :create_obj_subclass

    def is_target_ref?(opts = {})
      TargetRef.types(opts).include?(get_field?(:type))
    end

    def is_assembly_wide_node?
      update_object!(:type)
      self[:type].eql?('assembly_wide')
    end

    def self.assembly_node_print_form?(obj)
      if obj.is_a?(Node)
        if obj.get_field?(:display_name)
          obj.assembly_node_print_form()
        end
      end
    end

    def assembly_node_print_form
      if is_target_ref?()
        TargetRef.assembly_node_print_form(self)
      else
         get_field?(:display_name)
      end
    end

    #This is overwritten by node group subclasses
    def get_node_group_members
      #in case this called on superclass that is actually a node group
      if is_node_group?()
        create_obj_subclass().get_node_group_members()
      else
        [self]
      end
    end

    def self.create_from_model_handle(hash_scalar_values, model_handle, opts = {})
      ret = super(hash_scalar_values, model_handle)
      opts[:subclass] ? ret.create_obj_optional_subclass() : ret
    end

    # TODO: stub for feature_node_admin_state
    def persistent_hostname?
      false
    end

    ### virtual column defs
    #######################
    # TODO: write as sql fn for efficiency
    def has_pending_change
      ((get_field?(:action) || {})[:count] || 0) > 0
    end

    def status
      # assumes :is_deployed and :operational_status are set
      (not self[:is_deployed]) ? Type::Node.staged : self[:operational_status]
    end

    def target_id
      get_field?(:datacenter_datacenter_id)
    end

    def name
      get_field?(:display_name)
    end

    def pp_name_and_id(opts = {})
      first_word = (opts[:capitalize] ? 'Node' : 'node')
      "#{first_word} (#{name()}) with id (#{id})"
    end

    ########
    def self.stop_instances(nodes)
      CommandAndControl.stop_instances(nodes)
      nodes.each { |node| node.attribute.clear_host_addresses() }
    end

    #######################
    # standard get methods
    def get_target(additional_columns = [])
      sp_hash = {
        cols: [:id, :group_id, :display_name] + additional_columns,
        filter: [:eq, :id, target_id()]
      }
      Target::Instance.get_obj(model_handle(:target_instance), sp_hash)
    end

    def get_target_iaas_type
      get_target().get_iaas_type()
    end

    def get_target_iaas_credentials
      # TODO: Haris - When we support multiple IAAS we will need to modify logic here
      get_target().get_aws_compute_params()
    end

    def self.get_violations(id_handles)
      get_objs_in_set(id_handles, cols: [:violations]).map { |r| r[:violation] }
    end

    def get_project
      get_objects_col_from_sp_hash(cols: [:project]).first
    end

    def self.get_ports(id_handles)
      get_objs_in_set(id_handles, { cols: [:ports] }, keep_ref_cols: true).map { |r| r[:port] }
    end

    def get_port_links
      self.class.get_port_links([id_handle()])
    end

    def self.get_port_links(id_handles)
      ret = []
      ports = get_ports(id_handles)
      return ret if ports.empty?()
      port_ids = ports.map { |p| p[:id] }
      sp_hash = {
        cols: PortLink.common_columns(),
        filter: [:or, [:oneof, :input_id, port_ids], [:oneof, :output_id, port_ids]]
      }
      port_link_mh = ports.first.model_handle(:port_link)
      Model.get_objs(port_link_mh, sp_hash)
    end

    # TODO: gui based may remove
    def get_ports(*types)
      port_list = self.class.get_ports([id_handle])
      i18n = get_i18n_mappings_for_models(:component, :attribute)
      port_list.map { |port| port.filter_and_process!(i18n, *types) }.compact
    end

    ######### Model apis

    def get_assembly?(cols = nil)
      if assembly_id = get_field?(:assembly_id)
        sp_hash = {
        cols: cols || [:id, :group_id, :display_name],
        filter: [:eq, :id, assembly_id]
        }
        Assembly::Instance.get_objs(model_handle(:assembly_instance), sp_hash).first
      end
    end

    def self.list(model_handle, opts = {})
      target_filter = (opts[:target_idh] ? [:eq, :datacenter_datacenter_id, opts[:target_idh].get_id()] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:oneof, :type, [Type::Node.instance, Type::Node.staged, Type::Node.physical]], target_filter]
      sp_hash = {
        cols: common_columns() + [:assemblies],
        filter: filter
      }
      cols_except_name = common_columns() - [:display_name]
      get_objs(model_handle, sp_hash).map do |n|
        el = n.hash_subset(*cols_except_name)
        assembly_name = (n[:assembly] || {})[:display_name]
        el.merge(display_name: user_friendly_name(n[:display_name], assembly_name))
      end.sort { |a, b| a[:display_name] <=> b[:display_name] }
    end

    def self.list_wo_assembly_nodes(model_handle)
      filter = [:and, [:oneof, :type, [Type::Node.instance, Type::Node.staged]], [:eq, :assembly_id, nil]]
      sp_hash = {
        cols: common_columns() + [:assemblies],
        filter: filter
      }
      cols_except_name = common_columns() - [:display_name]
      get_objs(model_handle, sp_hash).map do |n|
        el = n.hash_subset(*cols_except_name)
        assembly_name = (n[:assembly] || {})[:display_name]
        el.merge(display_name: user_friendly_name(n[:display_name], assembly_name))
      end.sort { |a, b| a[:display_name] <=> b[:display_name] }
    end

    def self.legal_display_name?(display_name)
      display_name =~ LegalDisplayName
    end
    LegalDisplayName = /^[a-zA-Z0-9_:\[\]\.-]+$/

    def self.user_friendly_name(node_name, assembly_name = nil)
      assembly_name ? "#{assembly_name}::#{node_name}" : node_name
    end
    private_class_method :user_friendly_name

    # returns [node_name, assembly_name] later which could be nil
    def self.parse_user_friendly_name(name)
      node_name = assembly_name = nil
      if name =~ Regexp.new("(^.+)#{AssemblyNodeNameSep}(.+$)")
        node_name = Regexp.last_match(2)
        assembly_name = Regexp.last_match(1)
      else
        node_name = name
      end
      unless legal_display_name?(node_name)
        fail ErrorNameInvalid.new(node_name, :node)
      end
      [node_name, assembly_name]
    end
    private_class_method :parse_user_friendly_name
    AssemblyNodeNameSep = '::'

    def info(opts = {})
      ret = get_obj(cols: InfoCols).hash_subset(*InfoCols)
      opts[:print_form] ? info_print_form_processing!(ret) : ret
    end
    InfoCols = [:id, :display_name, :os_type, :type, :description, :status, :external_ref, :assembly_id]

    def info_print_form_processing!(info_hash)
      if external_ref = info_hash[:external_ref]
        private_dns = external_ref[:private_dns_name]
        if private_dns.is_a?(Hash)
          # then :private_dns_name is of form <public dns> => <private dns>
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
    def sanitize!
      self.class.sanitize!(self)
    end

    def info_about(about, _opts = {})
      case about
       when :components
        get_objs(cols: [:components], keep_ref_cols: true).map do |r|
          r[:component].convert_to_print_form!()
        end.sort { |a, b| a[:display_name] <=> b[:display_name] }
       when :attributes
        get_attributes_print_form()
       else
        fail Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
    end

    def find_violations
      cmps = get_objs(cols: [:components], keep_ref_cols: true)

      ret = []
      return ret if cmps.empty?

      cmps.each do |cmp|
        sp_hash = {
          cols: [:id, :type, :component_id, :service_id],
          filter: [:eq, :id, cmp[:component][:module_branch_id]]
        }
        branch = Model.get_obj(model_handle(:module_branch), sp_hash)

        sp_cmp_hash = {
          cols: [:id, :display_name, :dsl_parsed],
          filter: [:eq, :id, branch[:component_id]]
        }
        cmp_module = Model.get_obj(model_handle(:component_module), sp_cmp_hash)

        # ret << NodeViolations::NodeComponentParsingError.new(cmp_module[:display_name], "Component") unless cmp_module[:dsl_parsed]
        ret << NodeViolations::NodeComponentParsingError.new(cmp_module[:display_name], 'Component') unless branch.dsl_parsed?()
      end

      ret
    end

    #TODO: move to getting rid of namespace arg and using aug component template
    # component_template can be augmented and have keys with objects:
    # :module_branch
    # :component_module
    # :namespace
    # opts can have
    #  :namespace
    #  :component_title
    #  :idempotent
    def add_component(component_template, opts = {})
      component_title =  opts[:component_title]
      namespace = opts[:namespace] || (component_template[:namespace] && component_template[:namespace][:display_name])

      component_template.update_with_clone_info!()

      if module_branch = component_template[:module_branch]
        fail ErrorUsage.new("You are not allowed to add component '#{component_template[:display_name]}' that belongs to test-module.") if module_branch[:type].eql?('test_module')
      end

      override_attrs = { locked_sha: component_template.get_current_sha!() }

      component_type = component_template.get_field?(:component_type)
      if matching_cmp = Component::Instance.get_matching?(id_handle(), component_type, component_title)
        if opts[:idempotent]
          return matching_cmp.id_handle()
        else
          if component_title
            # Just doing check here when there is a title, and not treating singletones
            # because there is later constraint that picks up the singleton components
            fail ErrorUsage.new("Component (#{matching_cmp.print_form()}) already exists")
          end
        end
      end

      if title_attr_name = check_and_ret_title_attribute_name?(component_template, component_title)
        override_attrs = {
          ref: SQL::ColRef.cast(ComponentTitle.ref_with_title(component_type, component_title), :text),
          display_name: SQL::ColRef.cast(ComponentTitle.display_name_with_title(component_type, component_title), :text)
        }
      end
      clone_opts = { no_post_copy_hook: true, ret_new_obj_with_cols: [:id, :display_name], namespace: namespace }
      new_cmp = clone_into(component_template, override_attrs, clone_opts)
      new_cmp_idh = new_cmp.id_handle()
      if title_attr_name
        Component::Instance.set_title_attribute(new_cmp_idh, component_title, title_attr_name)
      end
      new_cmp_idh
    end

    def delete_component(component_idh)
      # first check that component_idh belongs to this instance
      sp_hash = {
        cols: [:id, :display_name],
        filter: [:and, [:eq, :id, component_idh.get_id()], [:eq, :node_node_id, id()]]
      }
      unless Model.get_obj(model_handle(:component), sp_hash)
        fail ErrorIdInvalid.new(component_idh.get_id(), :component)
      end
      Model.delete_instance(component_idh)
    end

    def self.check_valid_id(model_handle, id, assembly_id = nil)
      # filter does not include node group members
      filter =
        [:and,
         [:eq, :id, id],
         [:neq, :datacenter_datacenter_id, nil],
         assembly_id && [:eq, :assembly_id, assembly_id]
        ].compact
      opts = (assembly_id ? { no_error_if_no_match: true } : {})
      check_valid_id_helper(model_handle, id, filter, opts) ||
        check_valid_id__node_member(model_handle, id, assembly_id)
    end
    def self.check_valid_id__node_member(model_handle, id, assembly_id)
      assembly = NodeGroupRelation.get_node_member_assembly?(model_handle.createIDH(id: id))
      unless assembly && assembly.id == assembly_id
        fail ErrorIdInvalid.new(id, pp_object_type())
      end
      id
    end
    private_class_method :check_valid_id__node_member

    def self.name_to_id(model_handle, name, assembly_id = nil)
      node_name, assembly_name = parse_user_friendly_name(name)
      unless legal_display_name?(node_name)
        fail ErrorNameInvalid.new(node_name, :node)
      end
      assembly_id ||= assembly_name && Assembly::Instance.name_to_id(model_handle.createMH(:component), assembly_name)
      sp_hash =  {
        cols: [:id, :assembly_id],
        filter: [:and,
                 [:eq, :display_name, node_name],
                 [:neq, :datacenter_datacenter_id, nil],
                 [:eq, :assembly_id, assembly_id]]
      }
      name_to_id_helper(model_handle, name, sp_hash)
    end

    def git_authorized?
      external_ref.hash()[:git_authorized]
    end

    def set_git_authorized(bool_val)
      update_external_ref_field(:git_authorized, bool_val)
    end

    # TODO: should do this in the workflow
    # right now workflow has start participate that waits for start
    def self.start_instances(nodes)
      user_object  = CurrentSession.new.user_object()
      CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
        # invoking command to start the nodes
        CommandAndControl.start_instances(nodes)
      end
    end

    def get_and_update_status!
      # shortcut
      if key?(:is_deployed)
        return  Type::Node.staged unless self[:is_deployed]
      end
      update_obj!(:is_deployed, :external_ref, :operational_status)
      return  Type::Node.staged unless self[:is_deployed]
      get_and_update_operational_status!()
    end

    def get_and_update_operational_status!
      update_obj!(:type, :external_ref, :operational_status)
      if self[:type] == 'staged' # TODO: use Type methods
        return self[:admin_op_status]
      end
      op_status = CommandAndControl.get_node_operational_status(self)
      if op_status
        unless self[:operational_status] == op_status
          update_operational_status!(op_status)
          if op_status == 'stopped' # TODO: use Type methods
            # clear the hostaddress info
            attribute.clear_host_addresses()
          end
        end
      end
      op_status || self[:operational_status]
    end

    # attribute on node
    def update_operational_status!(op_status)
      update(operational_status: op_status.to_s)
      self[:operational_status] = op_status.to_s
    end

    def update_admin_op_status!(op_status)
      update(admin_op_status: op_status.to_s)
      self[:admin_op_status] = op_status.to_s
    end

    def update_agent_git_commit_id(agent_git_commit_id)
      update(agent_git_commit_id: agent_git_commit_id)
      self[:agent_git_commit_id] = agent_git_commit_id
    end

    def get_external_ref
      get_field?(:external_ref) || {}
    end

    def get_admin_op_status
      get_field?(:admin_op_status) || {}
    end

    def get_iaas_type
      ret = get_external_ref()[:type]
      ret && ret.to_sym
    end

    def instance_id
      get_external_ref()[:instance_id]
    end

    def pbuilderid
      self.class.pbuilderid(self)
    end
    def self.pbuilderid(node)
      unless ret = CommandAndControl.pbuilderid(node)
        fail Error.new("Node (#{node.get_field?(:display_name)}) with id (#{node.id}) does not have an #{PBuilderIDPrintName}")
      end
      ret
    end
    PBuilderIDPrintName = 'internal communication ID'

    def persistent_dns
      get_hostname_external_ref()[:persistent_dns]
    end

    def elastic_ip
      get_hostname_external_ref()[:elastic_ip]
    end

    def get_hostname_external_ref
      get_field?(:hostname_external_ref) || {}
    end
    private :get_hostname_external_ref

    # TODO: these may be depracted
    def update_ordered_component_ids(order)
      ordered_component_ids = "{ :order => [#{order.join(',')}] }"
      update(ordered_component_ids: ordered_component_ids)
      self[:ordered_component_ids] = ordered_component_ids
    end

    def get_ordered_component_ids
      ordered_component_ids = self[:ordered_component_ids]
      return [] unless ordered_component_ids
      eval(ordered_component_ids)[:order]
    end
    # end of these may be depracted

    def self.get_output_attrs_to_l4_input_ports(id_handles)
      rows = get_objs_in_set(id_handles, { cols: [:output_attrs_to_l4_input_ports] }, keep_ref_cols: true)
      return {} if rows.empty?
      # restructure so that get mapping from attribute_id to port
      ret = {}
      rows.each do |row|
        attr_id = row[:port_external_output][:external_attribute_id]
        ret[attr_id] ||= []
        ret[attr_id] << row[:port_l4_input]
      end
      ret
    end

    def get_ui_info(datacenter)
      datacenter_id_sym = datacenter[:id].to_s.to_sym
      node_id_sym = self[:id].to_s.to_sym
      # TODO: hack assumes that canm just take position from first node[:u1]
      ((datacenter[:ui] || {})[:items] || {})[node_id_sym] || (self[:ui] || {})[datacenter_id_sym] || (self[:ui] || {}).values.first
    end

    def update_ui_info!(ui, datacenter)
      datacenter_id_sym = datacenter[:id].to_s.to_sym
      node_id_sym = self[:id].to_s.to_sym
      self[:ui] ||= {}
      self[:ui][datacenter_id_sym] = ui
    end

    def get_users
      node_user_list = get_objects_from_sp_hash(columns: [:users])
      user_list = []
      # TODO: just putting in username, not uid or gid
      node_user_list.map do |u|
        attr = u[:attribute]
        val = attr[:value_asserted] || attr[:value_derived]
        (val && attr[:display_name] == 'username') ? { id: attr[:id], username: val, avatar_filename: 'generic-user-male.png' } : nil
      end.compact
    end

    def get_applications
      app_hash_list = get_objects_col_from_sp_hash({ columns: [:applications] }, :component)

      i18n = get_i18n_mappings_for_models(:component)
      app_hash_list.map do |component|
        name = component[:display_name]
        cmp_i18n = i18n_string(i18n, :component, name)
        component_el = { id: component[:id], name: name, i18n: cmp_i18n }
        component_icon_fn = ((component[:ui] || {})[:images] || {})[:tnail]
        component_el.merge(component_icon_fn ? { component_icon_filename: component_icon_fn } : {})
      end
    end

    # Method will take already allocated elastic IP and assign it deploy node.
    # Keep in mind this can only happen when node is 'running' state
    def associate_elastic_ip?
      if persistent_hostname?
        CommandAndControl.associate_elastic_ip(self)
      end
    end

    def associate_persistent_dns?
      CommandAndControl.associate_persistent_dns?(self)
    end

    # Method will remove DNS information for node, this happens when we do not persistent
    # DNS and by stopping node we do not need to keep DNS information
    def strip_dns_info!
      update(external_ref: self[:external_ref].merge(dns_name: nil, ec2_public_address: nil, private_dns_name: nil))
    end

    def get_node_service_checks
      return [] if get_objects_from_sp_hash(columns: [:monitoring_agents]).empty?

      # TODO: i18n treatment of service check names
      get_objects_col_from_sp_hash({ columns: [:monitoring_items__node] }, :monitoring_item)
    end

    def get_component_service_checks
      return [] if get_objects_from_sp_hash(columns: [:monitoring_agents]).empty?
      # TODO: i18n treatment of service check names
      i18n = get_i18n_mappings_for_models(:component)

      get_objects_from_sp_hash(columns: [:monitoring_items__component]).map do |r|
        cmp_name = r[:component][:display_name]
        cmp_info = { component_name: cmp_name, component_i18n: i18n_string(i18n, :component, cmp_name) }
        r[:monitoring_item].merge(cmp_info)
      end
    end

    # returns external attribute links and port links
    # returns [connected_links,dangling_links]
    def self.get_external_connected_links(id_handles)
      port_link_ret = get_conn_port_links(id_handles)
      attr_link_ret = get_conn_external_attr_links(id_handles)
      [port_link_ret[0] + attr_link_ret[0], port_link_ret[1] + attr_link_ret[1]]
    end

    # return ports links
    # returns [connected_links,dangling_links]
    def self.get_conn_port_links(id_handles, _opts = {})
      ret = [[], []]
      in_port_cols = [:id, :display_name, :input_port_links]
      ndx_in_links = {}
      get_objs_in_set(id_handles, columns: in_port_cols).each do |r|
        link = r[:port_link]
        ndx_in_links[link[:id]] = link
      end

      out_port_cols = [:id, :display_name, :output_port_links]
      ndx_out_links = {}
      get_objs_in_set(id_handles, columns: out_port_cols).each do |r|
        link = r[:port_link]
        ndx_out_links[link[:id]] = link
      end

      return ret if ndx_in_links.empty? && ndx_out_links.empty?

      connected_links = (ndx_in_links.keys & ndx_out_links.keys).map { |id| ndx_in_links[id] }

      dangling_links = (ndx_in_links.keys - ndx_out_links.keys).map { |id| ndx_in_links[id] }
      dangling_links += (ndx_out_links.keys - ndx_in_links.keys).map { |id| ndx_out_links[id] }
      [connected_links, dangling_links]
    end

    # return externally connected attribute links
    # returns [connected_links,dangling_links]
    def self.get_conn_external_attr_links(id_handles)
      ret = [[], []]

      ndx_in_links = get_objs_in_set(id_handles, cols: [:id, :input_attribute_links_cmp]).inject({}) do |h, r|
        link = r[:attribute_link]
        link[:type] == 'external' ? h.merge(link[:id] => link) : h
      end
      ndx_in_links = get_objs_in_set(id_handles, cols: [:id, :input_attribute_links_node]).inject(ndx_in_links) do |h, r|
        link = r[:attribute_link]
        link[:type] == 'external' ? h.merge(link[:id] => link) : h
      end

      ndx_out_links = get_objs_in_set(id_handles, cols: [:id, :output_attribute_links_cmp]).inject({}) do |h, r|
        link = r[:attribute_link]
        link[:type] == 'external' ? h.merge(link[:id] => link) : h
      end
      ndx_out_links = get_objs_in_set(id_handles, cols: [:id, :output_attribute_links_node]).inject(ndx_out_links) do |h, r|
        link = r[:attribute_link]
        link[:type] == 'external' ? h.merge(link[:id] => link) : h
      end

      return ret if ndx_in_links.empty? && ndx_out_links.empty?

      connected_links = (ndx_in_links.keys & ndx_out_links.keys).map { |id| ndx_in_links[id] }

      dangling_links = (ndx_in_links.keys - ndx_out_links.keys).map { |id| ndx_in_links[id] }
      dangling_links += (ndx_out_links.keys - ndx_in_links.keys).map { |id| ndx_out_links[id] }
      [connected_links, dangling_links]
    end

    # TODO: quick hack
    def self.get_wspace_display(id_handle)
      node_id = IDInfoTable.get_id_from_id_handle(id_handle)
      node_mh = id_handle.createMH(model_name: :node)
      node = get_objects(node_mh, { id: node_id }).first

      component_mh = node_mh.createMH(model_name: :component)
      component_ds = get_objects_just_dataset(component_mh, node_node_id: node_id)
      attr_where_clause = { is_port: true }
      # TODO: can prune what fields included
      attr_fs = Model::FieldSet.default(:attribute).with_added_cols(:component_component_id)
      attribute_mh = node_mh.createMH(model_name: :attribute)
      attribute_ds = get_objects_just_dataset(attribute_mh, attr_where_clause, FieldSet.opt(attr_fs))
      components = component_ds.graph(:left_outer, attribute_ds, component_component_id: :id).all
      node.merge(component: components)
    end
    #######################

    # TODO: should this be more generic and centralized?
    def get_objects_associated_components
      assocs = Model.get_objects(ModelHandle.new(@c, :assoc_node_component), node_id: self[:id])
      return [] if assocs.nil?
      assocs.map { |assoc| Model.get_object(IDHandle[c: @c, guid: assoc[:component_id]]) }
    end

    def get_obj_with_common_cols
      common_cols =  self.class.common_columns()
      ret = get_objs(cols: common_cols).first
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

      def type
        :parsing_error
      end

      def description
        "#{@type} '#{@component}' has syntax errors in DSL files."
      end
    end
  end
end
