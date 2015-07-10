module DTK; class Component
  class Instance < self
    r8_nested_require('instance', 'interpreted')

    def get_action_def?(method_name, opts = {})
      get_action_defs({ filter: [:eq, :method_name, method_name] }.merge(opts)).first
    end

    def get_action_defs(opts = {})
      filter = [:eq, :component_component_id, get_field?(:ancestor_id)]
      if opts[:filter]
        filter = [:and, filter, opts[:filter]]
      end
      sp_hash = {
        cols: opts[:cols] || ActionDef.common_columns(),
        filter: filter
      }
      Model.get_objs(model_handle(:action_def), sp_hash)
    end

    def self.get_objs(mh, sp_hash, opts = {})
      # TODO: might want to change to just :model_name == component_instance
      if [:component, :component_instance].include?(mh[:model_name])
        super(mh.createMH(:component), sp_hash, opts).map { |cmp| create_from_component(cmp) }
      else
        super
      end
    end

    def self.create_from_component(cmp)
      cmp && cmp.id_handle().create_object(model_name: :component_instance).merge(cmp)
    end

    def self.component_list_fields
      [:id, :group_id, :display_name, :component_type, :implementation_id, :basic_type, :version, :only_one_per_node, :external_ref, :node_node_id, :extended_base, :ancestor_id]
    end

    def self.get_matching?(node_idh, component_type, component_title)
      sp_hash = {
        cols: [:id, :display_name, :component_type, :ref],
        filter: [:and, [:eq, :node_node_id, node_idh.get_id()],
                 filter(component_type, component_title)
                   ]
      }
      cmp = Model.get_obj(node_idh.createMH(:component), sp_hash)
      cmp && create_from_component(cmp)
    end

    def has_title?
      ComponentTitle.title?(self)
    end

    def self.filter(component_type, component_title = nil)
      [:eq, :display_name, ComponentTitle.display_name_with_title?(component_type, component_title)]
    end

    def self.set_title_attribute(cmp_idh, component_title, title_attr_name = nil)
      title_attr_name ||= 'name'
      ref = title_attr_name
      sp_hash = {
        cols: [:id, :value_asserted],
        filter: [:and, [:eq, :display_name, title_attr_name],
                 [:eq, :component_component_id, cmp_idh.get_id()]]
      }
      unless title_attr = get_obj(cmp_idh.createMH(:attribute), sp_hash)
        Log.error('Unexpected that cannot find the title attribute')
        return
      end
      if title_attr[:value_asserted]
        Log.error('Unexpected that title attribute has value_asserted when set_title_attribute called')
      end
      title_attr.update(value_asserted: component_title, cannot_change: true, is_instance_value: true)
    end

    def add_title_field?
      self.class.add_title_fields?([self])
      self
    end
    def self.add_title_fields?(cmps)
      ret = cmps
      # TODO: for efficiency can look at ref it exsits and see if it indicates a title
      cmps_needing_titles = cmps.select do |cmp|
        cmp[:title].nil? && cmp.get_field?(:only_one_per_node) == false
      end
      return ret if cmps_needing_titles.empty?
      sp_hash = {
        cols: [:id, :group_id, :display_name, :component_component_id, :title],
        filter: [:oneof, :component_component_id, cmps_needing_titles.map { |cmp| cmp[:id] }]
      }
      ndx_attrs = {}
      get_objs(cmps.first.model_handle(:attribute), sp_hash).each do |a|
        if title = a[:title]
          ndx_attrs[a[:component_component_id]] = title
        end
      end
      cmps_needing_titles.each do |cmp|
        if title = ndx_attrs[cmp[:id]]
          cmp[:title] = title
        end
      end
      ret
    end

    def self.add_action_defs!(cmp_instances, opts = {})
      # add action defs that are from the template it is linked to
      ndx_template_idhs = {}
      ndx_template_id_to_instances = {}
      cmp_instances.each do |cmp_instance|
        template_id = cmp_instance.get_field?(:ancestor_id)
        ndx_template_idhs[template_id] ||= cmp_instance.id_handle(id: template_id)
        (ndx_template_id_to_instances[template_id] ||= []) << cmp_instance
      end

      ActionDef.get_ndx_action_defs(ndx_template_idhs.values, opts).each_pair do |template_id, action_defs|
        ndx_template_id_to_instances[template_id].each do |cmp_instance|
          cmp_instance[:action_defs] = action_defs
        end
      end
    end

    # these are port links that are connected on either end to the components in component_idhs
    def self.get_port_links(component_idhs)
      ret = []
      return ret if component_idhs.empty?
      sp_hash = {
        cols: [:id],
        filter: [:oneof, :component_id, component_idhs.map(&:get_id)]
      }
      port_mh = component_idhs.first.createMH(:port)
      port_ids = Model.get_objs(port_mh, sp_hash).map { |r| r[:id] }
      return ret if port_ids.empty?

      sp_hash = {
        cols: PortLink.common_columns(),
        filter: [:or, [:oneof, :input_id, port_ids], [:oneof, :output_id, port_ids]]
      }
      port_link_mh = component_idhs.first.createMH(:port_link)
      Model.get_objs(port_link_mh, sp_hash)
    end

    def get_component_template_parent
      unless row = get_obj(cols: [:instance_component_template_parent])
        fail Error.new('Unexpected that get_component_template_parent() called and nil result')
      end
      Component::Template.create_from_component(row[:component_template])
    end

    def self.get_ndx_intra_node_rels(cmp_idhs)
      cmps_with_deps = Component::Instance.get_components_with_dependency_info(cmp_idhs)
      ComponentOrder.get_ndx_cmp_type_and_derived_order(cmps_with_deps)
    end

    # TODO: may be able to deprecate below seeing that dependencies are on instances
    def self.get_components_with_dependency_info(cmp_idhs)
      ret = []
      return ret if cmp_idhs.empty?
      sp_hash = {
        cols: [:id, :inherited_dependencies, :extended_base, :component_type],
        filter: [:oneof, :id, cmp_idhs.map(&:get_id)]
      }
      cmp_mh = cmp_idhs.first.createMH()
      Model.get_objs(cmp_mh, sp_hash)
    end

    def print_form
      self.class.print_form(self)
    end

    def self.print_form(component, _namespace = nil)
      ret = component.get_field?(:display_name).gsub(/__/, '::')
      # removed namespace from list-components list (task DTK-1603)
      # ret = "#{namespace[:display_name]}/#{ret}" if namespace

      ret
    end

    def self.legal_display_name?(display_name)
      !ComponentTitle.parse_component_display_name(display_name).nil?
    end

    def self.version_print_form(component)
      ModuleBranch.version_from_version_field(component.get_field?(:version))
    end
  end
end; end
