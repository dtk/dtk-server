# TODO: finish moving the fns and mixins that relate just to template or instance to these files
module DTK
  class Assembly < Component
    r8_nested_require('assembly', 'list')
    r8_nested_require('assembly', 'template')
    r8_nested_require('assembly', 'instance')
    include ListMixin
    extend ListClassMixin

    def self.get_these_objs(mh, sp_hash, opts = {})
      Model.get_objs(mh.createMH(:component), sp_hash, opts).map { |cmp| create_from_component(cmp) }
    end
    def self.create_from_component(cmp)
      cmp && create_from_id_handle(cmp.id_handle()).merge(cmp)
    end

    ### standard get methods
    def get_assembly_level_attributes(filter_proc = nil)
      sp_hash = {
        cols: [:id, :display_name, :attribute_value, :data_type],
        filter: [:eq, :component_component_id, id()]
      }
      ret = Model.get_objs(model_handle(:attribute), sp_hash)
      if filter_proc
        ret.select { |r| filter_proc.call(r) }
      else
        ret
      end
    end

    def get_service_module
      get_obj_helper(:service_module)
    end

    def get_namespace
      service_module = get_service_module()

      sp_hash = {
        cols: [:id, :display_name],
        filter: [:eq, :id, service_module[:namespace_id]]
      }

      namespace = Model.get_obj(model_handle(:namespace), sp_hash)
    end

    def get_port_links(opts = {})
      filter = [:eq, :assembly_id, id()]
      if opts[:filter]
        filter = [:and, filter, opts[:filter]]
      end
      sp_hash = {
        cols: opts[:cols] || PortLink.common_columns(),
        filter: filter
      }
      Model.get_objs(model_handle(:port_link), sp_hash)
    end

    def get_matching_port_link(filter)
      opts = { filter: filter, ret_match_info: {} }
      matches = get_augmented_port_links(opts)
      case matches.size
        when 1
          matches.first
        when 0
          fail ErrorUsage.new("Cannot find component link#{error_message_condition(opts[:ret_match_info])}")
        else
          fail ErrorUsage.new("Multiple matching component links#{error_message_condition(opts[:ret_match_info])}")
      end
    end

    def error_message_condition(match_info)
      if clause = (match_info || {})[:clause]
        " with condition (#{clause})"
      else
        ''
      end
    end
    private :error_message_condition

    # augmented with the ports and nodes; component_id is on ports
    def get_augmented_port_links(opts = {})
      rows = get_objs(cols: [:augmented_port_links])
      # TODO: remove when have all create port link calls set port_link display name to service type
      rows.each { |r| r[:port_link][:display_name] ||= r[:input_port].link_def_name() }
      if filter = opts[:filter]
        post_filter =  port_link_filter_lambda_form(filter, opts)
        rows.reject! { |r| !post_filter.call(r) }
      end
      rows.map do |r|
        r[:port_link].merge(r.slice(:input_port, :output_port, :input_node, :output_node))
      end
    end

    def port_link_filter_lambda_form(filter, opts = {})
      if Aux.has_just_these_keys?(filter, [:port_link_id])
        port_link_id = filter[:port_link_id]
        if opts[:ret_match_info]
          opts[:ret_match_info][:clause] = "port_link_id = #{port_link_id}"
        end
        lambda { |r| r[:port_link][:id] == port_link_id }
      elsif Aux.has_just_these_keys?(filter, [:input_component_id])
        input_component_id = filter[:input_component_id]
        # not setting opts[:ret_match_info][:clause] because :input_component_id internally generated
        lambda { |r| r[:input_port][:component_id] == input_component_id }
      elsif Aux.has_only_these_keys?(filter, [:service_type, :input_component_id, :output_component_id])
        unless input_component_id = filter[:input_component_id]
          fail Error.new("Unexpected filter (#{filter.inspect})")
        end
        output_component_id = filter[:output_component_id]
        service_type = filter[:service_type]
        # not including conjunct with :input_component_id or output_component_id because internally generated
        if opts[:ret_match_info] && service_type
          opts[:ret_match_info][:clause] = "service_type = '#{service_type}'"
        end
        lambda do |r|
          (r[:input_port][:component_id] == input_component_id) &&
            (service_type.nil? || (r[:port_link][:display_name] == service_type)) &&
            (output_component_id.nil? || (r[:output_port][:component_id] == output_component_id))
        end
      else
        fail Error.new("Unexpected filter (#{filter.inspect})")
      end
    end
    private :port_link_filter_lambda_form

    # MOD_RESTRUCT: this must be removed or changed to reflect more advanced relationship between component ref and template
    def self.get_component_templates(assembly_mh, filter = nil)
      sp_hash = {
        cols: [:id, :display_name, :component_type, :component_templates],
        filter: [:and, [:eq, :type, 'composite'], [:neq, :library_library_id, nil], filter].compact
      }
      assembly_rows = get_objs(assembly_mh, sp_hash)
      assembly_rows.map { |r| r[:component_template] }
    end

    # this can be overwritten
    def self.get_component_attributes(_assembly_mh, _template_assembly_rows, _opts = {})
      []
    end

    ### end: standard get methods

    def self.get_default_component_attributes(assembly_mh, assembly_rows, opts = {})
      ret = []
      cmp_ids = assembly_rows.map { |r| (r[:nested_component] || {})[:id] }.compact
      return ret if cmp_ids.empty?

      # by defalut do not include derived values
      cols = [:id, :display_name, :value_asserted, :component_component_id, :is_instance_value] + (opts[:include_derived] ? [:value_derived] : [])
      sp_hash = {
        cols: cols,
        filter: [:oneof, :component_component_id, cmp_ids]
      }
      Model.get_objs(assembly_mh.createMH(:attribute), sp_hash)
    end

    def set_attributes(av_pairs, opts = {})
      # return attr_patterns
      Attribute::Pattern::Assembly.set_attributes(self, av_pairs, opts)
    end

    def self.ret_component_type(service_module_name, assembly_name)
      "#{service_module_name}__#{assembly_name}"
    end

    def self.pretty_print_version(assembly)
      assembly[:version] && ModuleBranch.version_from_version_field(assembly[:version])
    end

    def are_nodes_running_in_task?
      nodes = get_nodes(:id)
      running_nodes = Task::Status::Assembly.get_active_nodes(model_handle())

      return false if running_nodes.empty?
      interrsecting_nodes = (running_nodes.map(&:id) & nodes.map(&:id))

      !interrsecting_nodes.empty?
    end

    def self.is_template?(assembly_idh)
      assembly_idh.create_object().is_template?()
    end
    def is_template?
      not update_object!(:library_library_id)[:library_library_id].nil?
    end

    #### for cloning
    def add_model_specific_override_attrs!(override_attrs, _target_obj)
      override_attrs[:display_name] ||= SQL::ColRef.qualified_ref
      override_attrs[:updated] ||= false
    end

    ##############
    # TODO: looks like callers dont need all the detail; might just provide summarized info or instead pass arg that specifies sumamry level
    # also make optional whether materialize
    def get_node_assembly_nested_objects
      ndx_nodes = {}
      sp_hash = { cols: [:instance_nodes_and_cmps] }
      node_col_rows = get_objs(sp_hash)
      node_col_rows.each do |r|
        if node = r[:node]
          n = node.materialize!(Node.common_columns)
          node = ndx_nodes[n[:id]] ||= n.merge(components: [])
          node[:components] << r[:nested_component].materialize!(Component.common_columns())
        end
      end

      nested_node_ids = ndx_nodes.keys
      sp_hash = {
        cols: Port.common_columns(),
        filter: [:oneof, :node_node_id, nested_node_ids]
      }
      port_rows = Model.get_objs(model_handle(:port), sp_hash)
      port_rows.each do |r|
        node = ndx_nodes[r[:node_node_id]]
        (node[:ports] ||= []) << r.materialize!(Port.common_columns())
      end
      port_links = get_port_links()
      port_links.each { |pl| pl.materialize!(PortLink.common_columns()) }

      { nodes: ndx_nodes.values, port_links: port_links }
    end

    def is_assembly?
      true
    end

    def assembly?(opts = {})
      if opts[:subclass_object]
        self.class.create_assembly_subclass_object(self)
      else
        self
      end
    end
    def self.create_assembly_subclass_object(obj)
      obj.update_object!(:datacenter_datacenter_id)
      subclass_model_name = (obj[:datacenter_datacenter_id] ? :assembly_instance : :assembly_template)
      create_subclass_object(obj, subclass_model_name)
    end

    def get_component_with_attributes_unraveled(attr_filters = {})
      attr_vc = "#{assembly_type()}_assembly_attributes".to_sym
      sp_hash = { columns: [:id, :display_name, :component_type, :basic_type, attr_vc] }
      component_and_attrs = get_objects_from_sp_hash(sp_hash)
      return nil if component_and_attrs.empty?
      sample = component_and_attrs.first
      # TODO: hack until basic_type is populated
      # component = sample.subset(:id,:display_name,:component_type,:basic_type)
      component = sample.subset(:id, :display_name, :component_type).merge(basic_type: "#{assembly_type()}_assembly")
      node_attrs = { node_id: sample[:node][:id], node_name: sample[:node][:display_name] }
      filtered_attrs = component_and_attrs.map do |r|
        attr = r[:attribute]
        if attr and not attribute_is_filtered?(attr, attr_filters)
          cmp = r[:sub_component]
          cmp_attrs = { component_type: cmp[:component_type], component_name: cmp[:display_name] }
          attr.merge(node_attrs).merge(cmp_attrs)
        end
      end.compact
      attributes = AttributeComplexType.flatten_attribute_list(filtered_attrs)
      component.merge(attributes: attributes)
    end

    def assembly_type
      # TODO: stub; may use basic_type to distinguish between component and node assemblies
      :node
    end
    private :assembly_type
  end
end
