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
    require_relative('instance/service_link_mixin')
    require_relative('instance/service_link')
    require_relative('instance/action')
    require_relative('instance/violation')
    require_relative('instance/violations')
    require_relative('instance/update')
    require_relative('instance/list')
    require_relative('instance/get')
    require_relative('instance/component_template')
    require_relative('instance/add')
    require_relative('instance/delete')
    require_relative('instance/exec_delete')
    require_relative('instance/node_component')
    require_relative('instance/service_setting')
    require_relative('instance/node_status')
    require_relative('instance/lock')
    require_relative('instance/dsl_location')

    include ServiceLinkMixin
    include ViolationsMixin
    include ListMixin
    extend ListClassMixin
    include DeleteMixin
    extend DeleteClassMixin
    include ExecDeleteMixin
    include NodeComponentMixin
    include GetMixin
    extend GetClassMixin
    include ComponentTemplateMixin
    include AddMixin
    include NodeStatusMixin
    extend NodeStatusClassMixin
    include NodeStatusToFixMixin
    include DSLLocation::Mixin
    ACTION_DELIMITER = '.'

    # opts can have keys:
    #   :recursive
    #   :delete
    def uninstall(opts = {})
      # if target service instance delete all dependent service instances first
      if is_target_service_instance?
        staged_instances = get_staged_service_instances(self)

        if opts[:recursive]
          staged_instances.each{ |instance| instance.uninstall(opts) }
        elsif !staged_instances.empty?
          service_instances = []
          staged_instances.each{ |v| service_instances << v[:display_name] }
          fail ErrorUsage, "The target service instance '#{display_name}' cannot be deleted because there are service instances dependent on it (#{service_instances.join(', ')}). Please use flag '-r' to remove all."
        end
      end

      # do not allow to uninstall service instance if it's not empty
      nodes = get_leaf_nodes(remove_assembly_wide_node: true)
      if nodes.empty? && get_augmented_components.empty?
        CommonModule::ServiceInstance.delete_from_model_and_repo(self)
      else
        fail ErrorUsage, "Service instance '#{display_name}' cannot be deleted because it is not empty. You can either use '--delete' option to force uninstall service instance or execute 'dtk service delete' command first." unless opts[:delete]
        Assembly::Instance.delete(id_handle(self), destroy_nodes: true, uninstall: true) 
      end
    end

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

    def component_module_refs
      @component_module_refs ||= get_component_module_refs
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

    def has_assembly_wide_node?
      sp_hash = {
        cols: [:id, :display_name, :group_id, :ordered_component_ids],
        filter: [:and, [:eq, :type, Node::Type::Node.assembly_wide], [:eq, :assembly_id, id()]]
      }
      Model.get_obj(model_handle(:node), sp_hash)
    end

    # TODO: only add by old controller
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
      require 'debugger'
      Debugger.wait_connection = true
      Debugger.start_remote
      debugger
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

    
      breakpoint = check_for_breakpoint(task)
      return { task_id: task_id, breakpoint: breakpoint}
    end

    # Mock for testing
    def check_for_breakpoint(task)
      return true
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

    # version associated with assembly
    def assembly_version
      @assembly_version ||= ModuleVersion.ret(self)
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
