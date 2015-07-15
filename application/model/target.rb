module DTK
  class Target < Model
    r8_nested_require('target', 'clone')
    r8_nested_require('target', 'install_agents_helper')
    r8_nested_require('target', 'iaas_properties')
    r8_nested_require('target', 'instance')
    r8_nested_require('target', 'template')
    include Clone::Mixin

    def model_name #TODO: remove temp datacenter->target
      :datacenter
    end
    ##
    def self.common_columns
      [
       :id,
       :display_name,
       :name,
       :description,
       :type,
       :iaas_type,
       :iaas_properties,
       :project_id,
       :is_default_target,
       :provider,
       :ui
      ]
    end

    def self.name_to_id(model_handle, name)
      filter = [:and, [:eq, :display_name, name], object_type_filter()]
      name_to_id_helper(model_handle, name, filter: filter)
    end

    def self.check_valid_id(model_handle, id)
      filter = [:and, [:eq, :id, id], object_type_filter()]
      check_valid_id_helper(model_handle, id, filter)
    end

    def name
      get_field?(:display_name)
    end

    def type
      get_field?(:type)
    end

    def is_default?
      get_field?(:is_default_target)
    end

    def info_about(about, opts = {})
      case about
       when :assemblies
         opts.merge!(target_idh: id_handle())
         Assembly::Instance.list(model_handle(:component), opts)
       when :nodes
         Node::TargetRef.list(self)
       else
        fail Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
    end

    def self.check_valid_id(model_handle, id)
      check_valid_id_helper(model_handle, id, [:eq, :id, id])
    end

    def update_ui_for_new_item(new_item_id)
      update_obj!(:ui)
      target_ui = self[:ui] || { items: {} }
      target_ui[:items][new_item_id.to_s.to_sym] = {}
      update(ui: target_ui)
    end

    def get_ports(*types)
      port_list = get_objs(cols: [:node_ports]).map do |r|
        component_id = (r[:link_def] || {})[:component_component_id]
        component_id ? r[:port].merge(component_id: component_id) : r[:port]
      end
      i18n = get_i18n_mappings_for_models(:component, :attribute)
      port_list.map { |port| port.filter_and_process!(i18n, *types) }.compact
    end

    def get_node_group_members
      get_objs(cols: [:node_members]).map { |r| r[:node_member] }
    end

    def get_project
      project_id = get_field?(:project_id)
      id_handle(id: project_id, model_name: :project).create_object()
    end

    def get_node_config_changes
      nodes = get_objs(cols: [:nodes]).map { |r| r[:node] }
      ndx_changes = StateChange.get_ndx_node_config_changes(id_handle)
      nodes.inject({}) { |h, n| h.merge(n.id => ndx_changes[n.id] || StateChange.node_config_change__no_changes()) }
    end

    def install_agents
      InstallAgentsHelper.install(self)
    end

    ### TODO these should be moved to IAAS-spefic location
    def get_iaas_type
      get_field?(:iaas_type)
    end

    def get_security_group
      get_iaas_properties()[:security_group]
    end

    def get_region
      get_iaas_properties()[:region]
    end

    def get_keypair
      get_iaas_properties()[:keypair]
    end

    def get_security_group_set
      get_iaas_properties()[:security_group_set]
    end

    # returns aws params if pressent in iaas properties
    def get_aws_compute_params
      ret = {}
      @iaas_props ||= get_iaas_properties()
      if @iaas_props && (aws_key = @iaas_props[:key]) && (aws_secret = @iaas_props[:secret])
        ret.merge!(aws_access_key_id: aws_key, aws_secret_access_key: aws_secret)
        if region = @iaas_props[:region]
          ret.merge!(region: region)
        end
      end
      ret
    end

    ### TODO end: these should be moved to IAAS-spefic location

    def get_iaas_properties
      update_object!(:iaas_properties, :parent_id)
      iaas_properties = self[:iaas_properties]
      if parent_id = self[:parent_id]
        parent_provider = id_handle(id: parent_id).create_object(model_name: :target_instance)
        if parent_iaas_properties = parent_provider.get_field?(:iaas_properties)
          # specific properties take precedence over the parent's
          iaas_properties = parent_iaas_properties.merge(iaas_properties || {})
        end
      end
      iaas_properties
    end

    def get_and_update_nodes_status
      nodes = get_objs(cols: [:nodes]).map { |r| r[:node] }
      nodes.inject({}) { |h, n| h.merge(n.id => n.get_and_update_status!()) }
    end

    def destroy_and_delete_nodes
      nodes = get_objs(cols: [:nodes]).map { |r| r[:node] }
      nodes.each(&:destroy_and_delete)
    end

    def get_violation_info(severity = nil)
      get_objs(columns: [:violation_info]).map do |r|
        v = r[:violation]
        if severity.nil? || v[:severity] == severity
          v.merge(target_node_display_name: (r[:node] || {})[:display_name])
        end
      end.compact
    end

    def add_item(source_id_handle, override_attrs = {})
      # TODO: need to copy in avatar when hash["ui"] is non null
      override_attrs ||= {}
      source_obj = source_id_handle.create_object()
      clone_opts = source_obj.source_clone_info_opts()
      new_obj = clone_into(source_obj, override_attrs, clone_opts)
      new_obj && new_obj.id()
    end

    private

    def sub_item_model_names
      [:node]
    end
  end
  Datacenter = Target #TODO: remove temp datacenter->target
end
