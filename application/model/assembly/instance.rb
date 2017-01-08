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
    r8_nested_require('instance', 'exec_delete')
    r8_nested_require('instance', 'service_setting')
    r8_nested_require('instance', 'node_status')
    r8_nested_require('instance', 'lock')
    r8_nested_require('instance', 'dsl_location')

    include ServiceLinkMixin
    include ViolationsMixin
    include ListMixin
    extend ListClassMixin
    include DeleteMixin
    extend DeleteClassMixin
    include ExecDeleteMixin
    include GetMixin
    extend GetClassMixin
    include NodeStatusMixin
    extend NodeStatusClassMixin
    include NodeStatusToFixMixin
    include DSLLocation::Mixin
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

    def add_node_from_diff(node_name)
      target = get_target
      node_template = Node::Template.find_matching_node_template(target)

      override_attrs = {
        display_name: node_name,
        assembly_id: id
      }
      target.clone_into(node_template, override_attrs, node_template.source_clone_info_opts)
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
      new_obj
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

      # TODO: for some reason, node group members targets are populated with wrong target id; fixing that here
      node_group_members = node_group_obj.get_node_group_members
      node_group_members.each do |ng_member|
        ng_member.update(datacenter_datacenter_id: target[:id])
      end

      new_obj
    end

    def add_ec2_node_component(project, node)
      domain_component = Component::Domain::Node::Canonical
      cmp_name         = "#{domain_component.ec2_component_display_name_form}[#{node.name}]"
      namespace        = domain_component.ec2_namespace
      add_ec2_component(node, cmp_name, namespace, donot_update_workflow: true)
    end

    def add_ec2_properties_and_set_attributes(project, node, image, instance_size)
      domain_component = Component::Domain::Node::Properties
      cmp_name         = domain_component.ec2_component_display_name_form
      namespace        = domain_component.ec2_namespace

      new_node_component = add_ec2_component(node, cmp_name, namespace, auto_complete_links: true)

      node.update_object!(:display_name)
      node_name = node.display_name

      service = Service.new(self, components: [new_node_component])
      node = (CommandAndControl.create_nodes_from_service(service)||[]).first

      av_pairs = []
      if vpc_images = node.vpc_images
        av_pairs = validate_image_and_size(vpc_images, node_name, image, instance_size)
      end
      set_attributes(av_pairs) unless av_pairs.empty?

      node.validate_and_fill_in_values!
    end

    # opts can have keys 
    #   :auto_complete_links
    #   :donot_update_workflow
    def add_ec2_component(node, cmp_name, namespace, opts = {})
      Log.error("need to fix 'add_ec2_component so version is taken care of by making call to a method othaer than Component::Template.get_augmented_base_component_template?")
      unless aug_component_template =  Component::Template.get_augmented_base_component_template?(self, cmp_name, namespace) ||
        fail(ErrorUsage, "Component with identifier #{namespace.nil? ? '\'' : ('\'' + namespace + ':')}#{cmp_name}' does not exist!")
      end
      new_component_idh = add_component(node.id_handle, aug_component_template, ComponentTitle.parse_title?(cmp_name), Opts.new(opts.merge(project: project)))
      new_component_idh.create_object
    end
    private :add_ec2_component

    # aug_cmp_template is a component template augmented with keys having objects
    # :module_branch
    # :component_module
    # :namespace
    # opts can have
    #  :project 
    #  :idempotent
    #  :donot_update_workflow
    #  :splice_in_delete_action
    #  TODO: ...
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

        # update the module refs
        add_component__update_component_module_refs?(aug_cmp_template[:component_module], aug_cmp_template[:namespace], version: aug_cmp_template[:version])

        # recompute the locked module refs
        ModuleRefs::Lock.create_or_update(self)

        # unless opts[:donot_update_workflow]
        #  Task::Template::ConfigComponents.update_when_added_component_or_action?(self, node, component, component_title: component_title, skip_if_not_found: true)
        # end
        # TODO: DTK-2680: Aldin: for below see if we can simplify with above
        # TODO: DTK-2680: Rich: We will be able to simplify below with above after we change dtk-server/lib/common_dsl/object_logic/assembly/node/diff/delete.rb:90
        # where we add ec2::node[node_name].delete component action to workflow; we can change that to use TaskTemplate.insert_explict_delete_action?(assembly_instance, component, node, force_delete: opts[:force_delete])
        # which we use for other components
        unless opts[:donot_update_workflow]
          update_opts = { skip_if_not_found: true }
          if opts[:splice_in_delete_action]
            cmp_instance = Component::Instance.create_from_component(component)
            action_def = cmp_instance.get_action_def?('delete')
            update_opts.merge!(:action_def => action_def)
          end
          if component_title
            update_opts[:component_title] = component_title
            opts[:component_title] = component_title
          end
          Task::Template::ConfigComponents.update_when_added_component_or_action?(self, node, component, update_opts)
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
        node = node_idh.is_a?(Node) ? node_idh : node_idh.create_object()
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

        # set os_type if image attribute is changed; also validate size attribute if set
        validate_and_fill_image_or_size_attributes?(attr_patterns, opts) unless opts[:skip_image_and_size_validation]

        if opts[:update_meta]
          created_cmp_level_attrs = attr_patterns.select { |r| r.type == :component_level && r.created?() }
          unless created_cmp_level_attrs.empty?
            AssemblyModule::Component::Attribute.update(self, created_cmp_level_attrs)
          end
        end

        # generate dtk.service.yaml file again to reflect changes in required attributes
        if opts[:update_dsl]
          service_instance_branch = AssemblyModule::Service.get_service_instance_branch(self)
          RepoManager::Transaction.reset_on_error(service_instance_branch) do 
            CommonDSL::Generate::ServiceInstance.generate_dsl(self, service_instance_branch)
          end
          return CommonModule::ModuleRepoInfo.new(service_instance_branch)
        end
      end

      attr_patterns
    end

    def validate_and_fill_image_or_size_attributes?(attr_patterns, opts = {})
      image_attributes, size_attributes = ret_image_and_size_attributes(attr_patterns)
      reified_nodes = CommandAndControl.create_nodes_from_service(Service.new(self))

      unless image_attributes.empty?
        image_attributes.each do |image_attribute|
          node = reified_nodes.find { |rn| rn.node[:display_name].eql?(image_attribute[:node_name]) }
          node.validate_and_fill_in_ami_and_os_type!(rewrite_values: true, raise_errors: true)
        end
      end

      unless size_attributes.empty?
        size_attributes.each do |size_attribute|
          node = reified_nodes.find { |rn| rn.node[:display_name].eql?(size_attribute[:node_name]) }
          node.validate_and_fill_in_instance_type!(rewrite_values: true, raise_errors: true)
        end
      end
    end
    private :validate_and_fill_image_or_size_attributes?

    def ret_image_and_size_attributes(attr_patterns)
      image_attributes = []
      size_attributes  = []

      attr_patterns.each do |attr_pattern|
        if attr_pattern.type == :explicit_id
          attribute_obj  = Attribute.get_augmented(model_handle.createMH(:attribute), [:eq, :id, attr_pattern.id]).first
          attribute_name = attribute_obj[:display_name]

          if attribute_name.eql?('image')
            image_attributes << { display_name: attribute_name, node_name: attribute_obj[:node][:display_name] }
          elsif attribute_name.eql?('size')
            size_attributes << { display_name: attribute_name, node_name: attribute_obj[:node][:display_name] }
          end
        else
          attribute_name = attr_pattern.attribute_name
          if attribute_name.eql?('image')
            image_attributes << { display_name: attribute_name, node_name: attr_pattern.node[:display_name] }
          elsif attribute_name.eql?('size')
            size_attributes << { display_name: attribute_name, node_name: attr_pattern.node[:display_name] }
          end
        end
      end

      [image_attributes, size_attributes]
    end
    private :ret_image_and_size_attributes

    def exec(params)
      task_action = params[:task_action]

      # check if action is called on component or on service instance action
      if task_action
        component_id, method_name = nil, nil

        if match = task_action.match(/^(.*)\.(\w*)$/)
          component_id, method_name = $1, $2
        else
          component_id = task_action
        end

        # component_id, method_name = task_action.split(ACTION_DELIMITER)
        augmented_cmps = check_if_augmented_component(params, component_id, { include_assembly_cmps: true })

        # check if component and service level action with same name
        check_if_ambiguous(component_id) unless augmented_cmps.empty?

        # if task_action.include?(ACTION_DELIMITER) || !augmented_cmps.empty?
        if (task_action.include?(ACTION_DELIMITER) && method_name) || !augmented_cmps.empty?
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

      create_task_response = create_task(params)
      if create_task_response.has_key?(:empty_workflow) or
          # TODO: remove below for semantic conditions like :empty_workflow
          create_task_response.has_key?(:confirmation_message) or create_task_response.has_key?(:message)
        return create_task_response
      end

      execute_service_action(create_task_response[:task_id])
    end

    def uninstall(opts)
      # if target service instance delete all dependent service instances first
      if is_target_service_instance?
        staged_instances = get_staged_service_instances(self)

        if opts[:recursive]
          staged_instances.each{ |instance| instance.uninstall(opts) }
        elsif !staged_instances.empty?
          service_instances = []
          staged_instances.each{ |v| service_instances << v[:display_name] }
          fail ErrorUsage, "The target service cannot be deleted because there are service instances dependent on it (#{service_instances.join(', ')}). Please use flag '-r' to remove all."
        end
      end

      # do not allow to uninstall service instance if it's not empty
      nodes = get_leaf_nodes(remove_assembly_wide_node: true)
      if nodes.empty? && get_augmented_components.empty?
        CommonModule::ServiceInstance.delete_from_model_and_repo(self)
      else
        fail ErrorUsage, "Service instance cannot be deleted because it is not empty. You can either use '--delete' option to force uninstall service instance or execute 'dtk service delete' command first." unless opts[:delete]
        Assembly::Instance.delete(id_handle(self), destroy_nodes: true, uninstall: true) 
      end
    end

    def create_task(opts)
      if task_params = opts[:task_params]
        fail ErrorUsage, "Node/nodes params are not supported for service instance actions!" if task_params.key?('node') || task_params.key?('nodes')
      end

      if any_stopped_nodes?(:admin)
        if opts[:start_assembly].nil?
          instance_type = Workspace.is_workspace?(self) ? 'Workspace service' : 'Service instance' 
          return { confirmation_message: true, confirmation_message_text: "#{instance_type} is stopped, do you want to start it" }
        end
        opts.merge!(start_nodes: true, ret_nodes_to_start: [])
      else
        unless R8::Config[:debug][:disable_task_concurrent_check]
          if running_task = most_recent_task_is_executing?
            fail ErrorUsage, "Task with id '#{running_task.id}' is already running in assembly. Please wait until task is complete or cancel task."
          end
        end
      end

      unless task = Task.create_from_assembly_instance?(self, opts)
        return { empty_workflow: true }
      end

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

      # if executing component action but node not sent, it means execute assembly component action
      node = 'assembly_wide' unless node

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

      ret = {
        assembly_instance_id: self.id(),
        assembly_instance_name: self.display_name_print_form
      }

      begin
        task = Task.create_for_ad_hoc_action(self, component, opts) if component
        task = task.save_and_add_ids()
      rescue Task::Template::ParsingError => e
        return ret if params[:noop_if_no_action]
        raise e
      end

      workflow = Workflow.create(task)
      workflow.defer_execution()

      ret.merge!(task_id: task.id())
      ret
    end

    def check_if_augmented_component(params, component_id, opts = {})
      task_params = params[:task_params]

      if cmp_title = task_params && task_params['name']
        component_id = "#{component_id}[#{cmp_title}]"
      end

      new_opts = Opts.new(filter_component: component_id)
      augmented_cmps = get_augmented_components(new_opts)

      # filter out service instance components
      augmented_cmps.reject!{ |cmp| cmp[:node][:display_name].eql?('assembly_wide') } unless opts[:include_assembly_cmps]
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

    def set_as_default_target
      fail ErrorUsage.new("Service instance '#{self.get_field?(:display_name)}' is not a target service instance and cannot be set as default target!") unless is_target_service_instance?
      target = self.get_target
      Target::Instance.set_default_target(target, update_workspace_target: true)
    end

    def is_target_service_instance?
      specific_type = self.get_field?(:specific_type)
      return (specific_type && specific_type.eql?('target'))
    end

    def validate_image_and_size(vpc_images, node_name, image, instance_size)
      av_pairs = []
      current_image = nil

      return av_pairs if image.nil? && instance_size.nil?

      if image
        unless current_image = vpc_images[image]
          legal_value_list = vpc_images.keys.join(', ')
          fail ErrorUsage, "Image attribute on node '#{node_name}' has invalid value '#{image}'. Legal values are: #{legal_value_list}"
        end
        av_pairs << { pattern: "#{node_name}/image", value: image }
      end

      if instance_size
        if current_image
          legal_sizes = current_image['sizes'].keys
          unless legal_sizes.include?(instance_size)
            legal_value_list = legal_sizes.join(', ')
            fail ErrorUsage, "Size attribute on node '#{node_name}' has invalid value '#{instance_size}' for image '#{image}'. Legal values are: #{legal_value_list}"
          end
        else
          legal_sizes = vpc_images.map{ |_k, vpc_image| vpc_image['sizes'].keys }.uniq.flatten
          unless legal_sizes.include?(instance_size)
             legal_value_list = legal_sizes.join(', ')
            fail ErrorUsage, "Size attribute on node '#{node_name}' has invalid value '#{instance_size}'. Legal values are: #{legal_value_list}" 

          end
        end
        av_pairs << { pattern: "#{node_name}/size", value: instance_size } if instance_size
      end

      av_pairs
    end

    def self.exists?(mh, display_name)
      filter_array = 
        [ :and, 
          [:eq, :display_name, display_name], 
          [:eq, :type, 'composite'],
          [:neq, :datacenter_datacenter_id, nil]]
      get_obj(mh.createMH(:assembly_instance), sp_filter(filter_array))
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

    # opts can have keys:
    #  :version
    def add_component__update_component_module_refs?(component_module, namespace, opts = {})
      # TODO: should below instead be get_service_instance_branch
      service_instance_branch = AssemblyModule::Service.get_or_create_module_for_service_instance(self, opts)
      service_instance_branch.set_dsl_parsed!(true)
      component_module_refs = ModuleRefs.get_component_module_refs(service_instance_branch)

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

    def order_components_by_workflow(components, workflow_delete_order)
      return components unless workflow_delete_order

      ordered_components = []
      workflow_delete_order.each do |o_cmp|
        if matching_cmp = components.find{ |cmp| cmp[:display_name].eql?(o_cmp) }
          ordered_components << matching_cmp
        end
      end

      remaining_components = components - ordered_components
      ordered_components + remaining_components
    end

    def delete_recursive(service, parent_task, opts = {})
      staged_instances = get_staged_service_instances(service)

      staged_instances.each do |staged_instance|
        instance_subtask = delete_instance_task(staged_instance, opts)
        parent_task.add_subtask(instance_subtask)
      end
    end
    
    def get_staged_service_instances(service)
      staged_instances = Assembly::Instance.get(model_handle, target_idhs: [service.get_target.id_handle])
      staged_instances.reject!{ |si| si[:id] == service[:id] }
      staged_instances 
    end
     
  end
end
# TODO: hack to get around error in lib/model.rb:31:in `const_get
AssemblyInstance = Assembly::Instance
end
