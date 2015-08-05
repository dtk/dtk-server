module DTK; class  Assembly
  class Instance < self
    r8_nested_require('instance', 'service_link_mixin')
    r8_nested_require('instance', 'service_link')
    r8_nested_require('instance', 'action')
    r8_nested_require('instance', 'violation')
    r8_nested_require('instance', 'update')
    r8_nested_require('instance', 'list')
    r8_nested_require('instance', 'get')
    r8_nested_require('instance', 'delete')
    r8_nested_require('instance', 'service_setting')
    r8_nested_require('instance', 'node_status')
    include ServiceLinkMixin
    include ViolationMixin
    include ListMixin
    extend ListClassMixin
    include DeleteMixin
    extend DeleteClassMixin
    include GetMixin
    extend GetClassMixin
    include NodeStatusMixin
    extend NodeStatusClassMixin
    include NodeStatusToFixMixin

    def self.create_from_id_handle(idh)
      idh.create_object(model_name: :assembly_instance)
    end

    def clear_tasks(opts = {})
      opts_get_tasks = {}
      unless opts[:include_executing_task]
        opts_get_tasks[:filter_proc] = lambda do |r|
          !r[:task].has_status?(:executing)
        end
      end
      task_idhs = get_tasks(opts_get_tasks).map(&:id_handle)
      Model.delete_instances(task_idhs) unless task_idhs.empty?
      task_idhs
    end

    def get_info__flat_list(opts = {})
      filter = [:eq, :id, id()]
      self.class.get_info__flat_list(model_handle(), { filter: filter }.merge(opts))
    end

    def remove_empty_nodes(nodes, opts = {})
      filter = [:eq, :id, id()]
      self.class.remove_empty_nodes(model_handle(), nodes, { filter: filter }.merge(opts))
    end

    def self.remove_empty_nodes(assembly_mh, nodes, opts = {})
      assembly_empty_nodes = {}
      target_idh = opts[:target_idh]
      target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id()] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:eq, :type, 'composite'], target_filter, opts[:filter]].compact
      col, needs_empty_nodes = list_virtual_column?(opts[:detail_level])
      cols = [:id, :ref, :display_name, :group_id, :component_type, :version, :created_at, col].compact
      ret = get(assembly_mh, { cols: cols }.merge(opts))

      nodes_ids = ret.map { |r| (r[:node] || {})[:id] }.compact
      sp_hash = {
        cols: [:id, :display_name, :component_type, :version, :instance_nodes_and_assembly_template],
        filter: filter
      }
      assembly_empty_nodes = get_objs(assembly_mh, sp_hash).reject { |r| nodes_ids.include?((r[:node] || {})[:id]) }

      assembly_empty_nodes.each do |en|
        if node = en[:node]
          nodes.delete_if { |n| n[:id] == node[:id] }
        end
      end

      nodes
    end

    # returns column plus whether need to pull in empty assembly nodes (assembly nodes w/o any components)
    #[col,empty_assem_nodes]
    def self.list_virtual_column?(detail_level = nil)
      empty_assem_nodes = false
      col =
        if detail_level.nil?
          nil
        elsif detail_level == 'nodes'
          empty_assem_nodes = true
          # TODO: use below for component detail and introduce a more succinct one for nodes
          :instance_nodes_and_cmps_summary
        elsif detail_level == 'components'
          empty_assem_nodes = true
          :instance_nodes_and_cmps_summary
        else
          fail Error.new("not implemented list_virtual_column at detail level (#{detail_level})")
        end
      [col, empty_assem_nodes]
    end
    private_class_method :list_virtual_column?

    def add_node(node_name, node_binding_rs = nil, opts = {})
      # if assembly_wide node (used to add component directly on service_instance/assembly_template/workspace)
      # check if type = 'assembly_wide'
      # or check by name if regular node
      check = opts[:assembly_wide] ? [:eq, :type, 'assembly_wide'] : [:eq, :display_name, node_name]

      # check if node has been added already
      if get_node?(check)
        fail ErrorUsage.new("Node (#{node_name}) already belongs to #{pp_object_type} (#{get_field?(:display_name)})")
      end

      target = get_target()
      node_template = Node::Template.find_matching_node_template(target, node_binding_ruleset: node_binding_rs)

      override_attrs = {
        display_name: node_name,
        assembly_id: id()
      }
      override_attrs.merge!(type: 'assembly_wide') if opts[:assembly_wide]
      clone_opts = node_template.source_clone_info_opts()
      new_obj = target.clone_into(node_template, override_attrs, clone_opts)
      new_obj && new_obj.id_handle()
    end

    def add_node_group(node_group_name, node_binding_rs, cardinality)
      # check if node has been added already
      if get_node?([:eq, :display_name, node_group_name])
        fail ErrorUsage.new("Node (#{node_group_name}) already belongs to #{pp_object_type} (#{get_field?(:display_name)})")
      end

      target = get_target()
      node_template = Node::Template.find_matching_node_template(target, node_binding_ruleset: node_binding_rs)

      self.update_object!(:display_name)
      ref = SQL::ColRef.concat('assembly--', "#{self[:display_name]}--#{node_group_name}")

      override_attrs = {
        display_name: node_group_name,
        assembly_id: id(),
        type: 'node_group_staged',
        ref: ref
      }

      clone_opts = node_template.source_clone_info_opts()
      new_obj = target.clone_into(node_template, override_attrs, clone_opts)
      Node::NodeAttribute.create_or_set_attributes?([new_obj], :cardinality, cardinality)

      node_group_obj = new_obj.create_obj_optional_subclass()
      node_group_obj.add_group_members(cardinality.to_i)

      new_obj && new_obj.id_handle()
    end

    # aug_cmp_template is a component template augmented with keys having objects
    # :module_branch
    # :component_module
    # :namespace
    # opts can have
    #  :idempotent
    #  :donot_update_workflow
    def add_component(node_idh, aug_cmp_template, component_title, opts = {})
      # if node_idh it means we call add component from node context
      # else we call from service instance/workspace and use assembly_wide node
      if node_idh
        # first check that node_idh is directly attached to the assembly instance
        # one reason it may not be is if its a node group member
        sp_hash = {
          cols: [:id, :display_name, :group_id, :ordered_component_ids],
          filter: [:and, [:eq, :id, node_idh.get_id()], [:eq, :assembly_id, id()]]
        }

        unless node = Model.get_obj(model_handle(:node), sp_hash)
          if node_group = is_node_group_member?(node_idh)
            fail ErrorUsage.new("Not implemented: adding a component to a node group member; a component can only be added to the node group (#{node_group[:display_name]}) itself")
          else
            fail ErrorIdInvalid.new(node_idh.get_id(), :node)
          end
        end
      else
        node = create_assembly_wide_node?()
      end

      cmp_instance_idh = nil

      Transaction do
        cmp_instance_idh = node.add_component(aug_cmp_template, opts.merge(component_title: component_title))
        add_component__update_component_module_refs?(aug_cmp_template[:component_module], aug_cmp_template[:namespace])
        unless opts[:donot_update_workflow]
          Task::Template::ConfigComponents.update_when_added_component?(self, node, cmp_instance_idh.create_object(), component_title, skip_if_not_found: true)
        end
      end
      cmp_instance_idh
    end

    def add_component__update_component_module_refs?(component_module, namespace)
      assembly_branch = AssemblyModule::Service.get_or_create_assembly_branch(self)
      assembly_branch.set_dsl_parsed!(true)
      component_module_refs = ModuleRefs.get_component_module_refs(assembly_branch)
      cmp_modules_with_namespaces = component_module.merge(namespace_name: namespace[:display_name])
      if update_needed = component_module_refs.update_object_if_needed!([cmp_modules_with_namespaces])
        # This saves teh upadte to the object model
        component_module_refs.update()
      end
    end
    private :add_component__update_component_module_refs?

    def create_assembly_wide_node?
      sp_hash = {
        cols: [:id, :display_name, :group_id, :ordered_component_ids],
        filter: [:and, [:eq, :type, 'assembly_wide'], [:eq, :assembly_id, id()]]
      }
      node = Model.get_obj(model_handle(:node), sp_hash)

      unless node
        node_idh = add_node('assembly_wide', nil, assembly_wide: true)
        node = node_idh.create_object()
      end

      node
    end

    def has_assembly_wide_node?
      sp_hash = {
        cols: [:id, :display_name, :group_id, :ordered_component_ids],
        filter: [:and, [:eq, :type, 'assembly_wide'], [:eq, :assembly_id, id()]]
      }
      Model.get_obj(model_handle(:node), sp_hash)
    end

    #rturns a node group object if node_idh is a node group member of this assembly instance
    def is_node_group_member?(node_idh)
      sp_hash = {
        cols: [:id, :display_name, :group_id, :node_members],
        filter: [:eq, :assembly_id, id()]
      }
      node_id = node_idh.get_id()
      Model.get_objs(model_handle(:node), sp_hash).find { |ng| ng[:node_member].id == node_id }
    end
    private :is_node_group_member?

    def add_assembly_template(assembly_template)
      target = get_target()
      assem_id_assign = { assembly_id: id() }
      # TODO: want to change node names if dups
      override_attrs = { node: assem_id_assign.merge(component_ref: assem_id_assign), port_link: assem_id_assign }
      clone_opts = { ret_new_obj_with_cols: [:id, :type] }
      new_assembly_part_obj = target.clone_into(assembly_template, override_attrs, clone_opts)
      self.class.delete_instance(new_assembly_part_obj.id_handle())
      id_handle()
    end

    def set_attribute(attribute, value, opts = {})
      set_attributes([{ pattern: attribute, value: value }], opts)
    end

    def set_attributes(av_pairs, opts = {})
      attr_patterns = nil
      Transaction do
        # super does the processing that sets the actual attributes then if opts[:update_meta] set
        # then if opts[:update_meta] set meta info can be changed on the assembly module
        attr_patterns = super

        # return if ambiguous attributes (component and node have same name and attribute)
        return attr_patterns if attr_patterns.is_a?(Hash) && attr_patterns[:ambiguous]

        if opts[:update_meta]
          created_cmp_level_attrs = attr_patterns.select { |r| r.type == :component_level && r.created?() }
          unless created_cmp_level_attrs.empty?
            AssemblyModule::Component::Attribute.update(self, created_cmp_level_attrs)
          end
        end
      end
      attr_patterns
    end

    def self.check_valid_id(model_handle, id)
      filter =
        [:and,
         [:eq, :id, id],
         [:eq, :type, 'composite'],
         [:neq, :datacenter_datacenter_id, nil]]
      check_valid_id_helper(model_handle, id, filter)
    end

    def self.name_to_id(model_handle, name)
      parts = name.split('/')
      augmented_sp_hash =
        if parts.size == 1
          { cols: [:id],
            filter: [:and,
                     [:eq, :display_name, parts[0]],
                     [:eq, :type, 'composite'],
                     [:neq, :datacenter_datacenter_id, nil]]
          }
        elsif parts.size == 2
          { cols: [:id, :component_type, :target],
            filter: [:and,
                     [:eq, :display_name, parts[1]],
                     [:eq, :type, 'composite']],
            post_filter: lambda { |r| r[:target][:display_name] == parts[0] }
          }
        else
          fail ErrorNameInvalid.new(name, pp_object_type())
        end
      name_to_id_helper(model_handle, name, augmented_sp_hash)
    end

    # TODO: probably move to Assembly
    def model_handle(mn = nil)
      super(mn || :component)
    end
  end
end
# TODO: hack to get around error in lib/model.rb:31:in `const_get
AssemblyInstance = Assembly::Instance
end
