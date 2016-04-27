#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class  Assembly
  class Instance < self
    r8_require('../service_associations')
    r8_nested_require('instance', 'service_link_mixin')
    r8_nested_require('instance', 'service_link')
    r8_nested_require('instance', 'action')
    r8_nested_require('instance', 'violation')
    r8_nested_require('instance', 'violations')
    r8_nested_require('instance', 'update')
    r8_nested_require('instance', 'list')
    r8_nested_require('instance', 'get')
    r8_nested_require('instance', 'delete')
    r8_nested_require('instance', 'service_setting')
    r8_nested_require('instance', 'node_status')
    r8_nested_require('instance', 'lock')

    include ServiceLinkMixin
    include ViolationsMixin
    include ListMixin
    extend ListClassMixin
    include DeleteMixin
    extend DeleteClassMixin
    include GetMixin
    extend GetClassMixin
    include NodeStatusMixin
    extend NodeStatusClassMixin
    include NodeStatusToFixMixin

    ACTION_DELIMITER = '.'

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

    def add_node(node_name, node_binding_rs = nil, opts = {})
      # if assembly_wide node (used to add component directly on service_instance/assembly_template/workspace)
      # check if type = Node::Type::Node.assembly_wide
      # or check by name if regular node
      check = opts[:assembly_wide] ? [:eq, :type, Node::Type::Node.assembly_wide] : [:eq, :display_name, node_name]

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
      opts.merge!(detail_to_include: [:component_dependencies])

      Transaction do
        # add the component
        cmp_instance_idh = node.add_component(aug_cmp_template, opts.merge(component_title: component_title))
        component = cmp_instance_idh.create_object()

        # update the mnodule refs
        add_component__update_component_module_refs?(aug_cmp_template[:component_module], aug_cmp_template[:namespace], aug_cmp_template[:version])

        # recompute the locked module refs
        ModuleRefs::Lock.create_or_update(self)

        unless opts[:donot_update_workflow]
          Task::Template::ConfigComponents.update_when_added_component?(self, node, component, component_title, skip_if_not_found: true)
        end

        if opts[:auto_complete_links]
          associations = ServiceAssociations.get_for_child(opts[:project], self)
          opts[:parent_service_instance] = associations unless associations.empty?
          LinkDef::AutoComplete.autocomplete_component_links(self, [component], opts)
        end
      end

      cmp_instance_idh
    end

    def create_assembly_wide_node?
      sp_hash = {
        cols: [:id, :display_name, :group_id, :ordered_component_ids],
        filter: [:and, [:eq, :type, Node::Type::Node.assembly_wide], [:eq, :assembly_id, id()]]
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
        filter: [:and, [:eq, :type, Node::Type::Node.assembly_wide], [:eq, :assembly_id, id()]]
      }
      Model.get_obj(model_handle(:node), sp_hash)
    end

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

    def exec(params)
      task_action = params[:task_action]

      # check if action is called on component or on service instance action
      if task_action
        component_id, method_name = task_action.split(ACTION_DELIMITER)
        augmented_cmps = check_if_augmented_component(params, component_id)

        # check if component and service level action with same name
        check_if_ambiguous(component_id) unless augmented_cmps.empty?

        if task_action.include?(ACTION_DELIMITER) || !augmented_cmps.empty?
          return execute_cmp_action(params, component_id, method_name, augmented_cmps)
        end
      end

      skip_violations = params[:skip_violations]
      unless skip_violations
        violation_objects = find_violations()

        violation_table = violation_objects.map do |v|
          { type: v.type(), description: v.description() }
        end.sort { |a, b| a[:type].to_s <=> b[:type].to_s }

        return { violations: violation_table.uniq } unless violation_table.empty?
      end

      task = create_task(params)
      return task if task.has_key?(:confirmation_message) || task.has_key?(:message)

      execute_service_action(task[:task_id])
    end

    def create_task(opts)
      if task_params = opts[:task_params]
        fail ErrorUsage, "Node/nodes params are not supported for service instance actions!" if task_params.key?('node') || task_params.key?('nodes')
      end

      if any_stopped_nodes?(:admin)
        return { confirmation_message: true } if opts[:start_assembly].nil?
        opts.merge!(start_nodes: true, ret_nodes_to_start: [])
      else
        unless R8::Config[:debug][:disable_task_concurrent_check]
          if running_task = most_recent_task_is_executing?
            fail ErrorUsage, "Task with id '#{running_task.id}' is already running in assembly. Please wait until task is complete or cancel task."
          end
        end
      end

      task = Task.create_from_assembly_instance?(self, opts)
      return { message: "There are no steps in the workflow to execute" } unless task

      task.save!()
      Node.start_instances(opts[:ret_nodes_to_start]) unless (opts[:ret_nodes_to_start]||[]).empty?

      return { task_id: task.id }
    end

    def execute_service_action(task_id)
      task_idh = id_handle().createIDH(id: task_id, model_name: :task)
      task     = Task::Hierarchical.get_and_reify(task_idh)
      workflow = Workflow.create(task)
      workflow.defer_execution()
      return { task_id: task_id }
    end

    def execute_cmp_action(params, component_id, method_name, augmented_cmps)
      task_params = nil
      component   = nil
      node        = nil
      task        = nil

      task_params = params[:task_params]
      node        = (task_params['node'] || task_params['nodes']) if task_params

      message = "There are no components with identifier '#{component_id}'"
      message += " on node '#{node}'" if node
      fail ErrorUsage, "#{message}!" if augmented_cmps.empty?

      opts = {}
      opts.merge!(method_name: method_name) if method_name
      opts.merge!(task_params: task_params) if task_params

      if node
        # if node has format node:id it means use single node from node group
        if node_match = node.include?(':') && node.match(/([\w-]+)\:{1}(\d+)/)
          opts.merge!(node_group_member: node)
          node, node_id = $1, $2
        end

        # filter component that belongs to specified node
        component = augmented_cmps.find{|cmp| cmp[:node][:display_name].eql?(node)}
        fail ErrorUsage, "#{message}!" unless component
      else
        if augmented_cmps.size == 1
          component = augmented_cmps.first

          # do not allow execution of service instance component actions
          fail ErrorUsage, "You are not allowed to execute action on service instance component '#{component_id}'!" if (component[:node] && component[:node][:display_name].eql?('assembly_wide'))
        else
          # if multiple nodes have component sent by user then execute that component action on all nodes
          task = Task.create_top_level(model_handle(:task), self, { task_action: "component_actions", temporal_order: 'concurrent' })

          augmented_cmps.each do |cmp|
            # skip execution of component actions on assembly wide node (service instance component)
            next if (cmp[:node] && cmp[:node][:display_name].eql?('assembly_wide'))

            subtask = Task.create_for_ad_hoc_action(self, cmp, opts)
            task.add_subtask(subtask) if subtask
          end
        end
      end

      task = Task.create_for_ad_hoc_action(self, component, opts) if component
      task = task.save_and_add_ids()

      workflow = Workflow.create(task)
      workflow.defer_execution()

      {
        assembly_instance_id: self.id(),
        assembly_instance_name: self.display_name_print_form,
        task_id: task.id()
      }
    end

    def check_if_augmented_component(params, component_id)
      task_params = params[:task_params]

      if cmp_title = task_params && task_params['name']
        component_id = "#{component_id}[#{cmp_title}]"
      end

      opts = Opts.new(filter_component: component_id)
      augmented_cmps = get_augmented_components(opts)

      # filter out service instance components
      augmented_cmps.reject!{ |cmp| cmp[:node][:display_name].eql?('assembly_wide') }
      augmented_cmps
    end

    # check if service instance action with same name as component action and raise ambiguity error
    def check_if_ambiguous(action_name)
      service_actions = get_task_templates(set_display_names: true)
      service_actions.reject!{ |action| !action[:display_name].eql?(action_name) }

      fail ErrorUsage, "There is ambiguity between service instance action and component action with name '#{action_name}'!" unless service_actions.empty?
    end

    def most_recent_task_is_executing?
      if task = ::DTK::Task.get_top_level_most_recent_task(model_handle(:task), [:eq, :assembly_id, self.id()])
        task.has_status?(:executing) && task
      end
    end

    def set_as_default_target()
      fail ErrorUsage.new("Service instance '#{self.get_field?(:display_name)}' is not a target service instance and cannot be set as default target!") unless is_target_service_instance?
      target = self.get_target
      Target::Instance.set_default_target(target, update_workspace_target: true)
    end

    def is_target_service_instance?
      specific_type = self.get_field?(:specific_type)
      return (specific_type && specific_type.eql?('target'))
    end

    def self.exists?(target, display_name)
      !!find_by_name?(target, display_name)
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

    private

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

    def self.find_by_name?(target, display_name)
      sp_hash = {
        cols:  [:id],
        filter:  [:and,
         [:eq, :display_name, display_name],
         [:eq, :datacenter_datacenter_id, target.id],                  
         [:eq, :type, 'composite']]
      }
      
      get_obj(target.model_handle(:assembly_instance), sp_hash)
    end

    def add_component__update_component_module_refs?(component_module, namespace, version_info = nil)
      assembly_branch = AssemblyModule::Service.get_or_create_assembly_branch(self)
      assembly_branch.set_dsl_parsed!(true)
      component_module_refs = ModuleRefs.get_component_module_refs(assembly_branch)

      # TODO: not sure if the best way to handle using different version of component module
      # unless we delete existing it will not update if version is changed
      cmp_modules = component_module_refs.component_modules
      cmp_modules.delete(component_module[:display_name].to_sym)

      version_info = nil if version_info == 'master'
      cmp_modules_with_namespaces = component_module.merge(namespace_name: namespace[:display_name], version_info: version_info)
      if update_needed = component_module_refs.update_object_if_needed!([cmp_modules_with_namespaces])
        # This saves teh upadte to the object model
        component_module_refs.update()
      end
    end

    #returns a node group object if node_idh is a node group member of this assembly instance
    def is_node_group_member?(node_idh)
      sp_hash = {
        cols: [:id, :display_name, :group_id, :node_members],
        filter: [:eq, :assembly_id, id()]
      }
      node_id = node_idh.get_id()
      Model.get_objs(model_handle(:node), sp_hash).find { |ng| ng[:node_member].id == node_id }
    end

  end
end
# TODO: hack to get around error in lib/model.rb:31:in `const_get
AssemblyInstance = Assembly::Instance
end
