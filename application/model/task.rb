module DTK
  class Task < Model
    r8_nested_require('task','hierarchical')
    r8_nested_require('task','get')
    r8_nested_require('task','create')
    r8_nested_require('task','status')
    r8_nested_require('task','action')
    r8_nested_require('task','template')
    r8_nested_require('task','stage')
    r8_nested_require('task','node_group_processing')
    r8_nested_require('task','action_results')
    r8_nested_require('task','qualified_index')
    include HierarchicalMixin
    include GetMixin
    extend GetClassMixin
    extend CreateClassMixin
    include StatusMixin
    include NodeGroupProcessingMixin
    include Status::TableForm::Mixin
    include ActionResults::Mixin

    def self.common_columns
      [
       :id,
       :display_name,
       :group_id,
       :status,
       :result,
       :updated_at,
       :created_at,
       :started_at,
       :ended_at,
       :task_id,
       :temporal_order,
       :position,
       :executable_action_type,
       :executable_action,
       :commit_message,
       :assembly_id,
       :target_id
      ]
    end

    # can be :sequential, :concurrent, :executable_action, or :decomposed_node_group
    def basic_type
      if ea = self[:executable_action]
        ea[:decomposed_node_group] ? :decomposed_node_group : :executable_action
      elsif self[:temporal_order] == 'sequential'
        :sequential
      elsif self[:temporal_order] == 'concurrent'
        :concurrent
      end
    end

    # can be :sequential, :concurrent, or :leaf
    def temporal_type
      case basic_type()
        when :decomposed_node_group, :concurrent then :concurrent
        when :sequential then :sequential
        else :leaf
      end
    end

    def has_status?(status)
      Status::Type.task_has_status?(self, status)
    end

    # TODO: see if we can deprecate guarded_by
    # returns list (possibly empty) of subtask idhs that guard this
    def guarded_by(external_guards)
      ret = []
      ea = executable_action()
      return ret unless node_id = ea.respond_to?(:node_id) && ea.node_id
      task_ids = external_guards.select { |g| g[:guarded][:node][:id] }.map { |g| g[:guard][:task_id] }.uniq
      task_ids.map { |task_id| id_handle(id: task_id) }
    end

    def assembly
      if assembly_id = get_field?(:assembly_id)
        id_handle(model_name: :assembly, id: assembly_id).create_object()
      end
    end

    def add_event(event_type, result = nil)
      if event = TaskEvent.create_event?(event_type, self, result)
        type = event.delete(:type) || event_type
        row = {
          content: event.to_hash,
          ref: 'task_event',
          type: type.to_s,
          task_id: id()
        }
        Model.create_from_rows(child_model_handle(:task_event), [row], convert: true)
        event
      end
    end

    # returns [event,error-array]
    def add_event_and_errors(event_type, error_source, errors_in_result)
      ret = [nil, nil]
      # process errors and strip out from what is passed to add event
      normalized_errors =
        if error_source == :config_agent
          config_agent = get_config_agent()
          components = component_actions().map { |a| a[:component] }
          errors_in_result.map { |err| config_agent.interpret_error(err, components) }
        else
          # TODO: stub
          errors_in_result
        end
      errors = add_errors(normalized_errors)
      # TODO: want to remove calls in function below from needing to know result format
      event = add_event(event_type, data: { errors: errors_in_result })
      [event, errors]
    end

    def add_errors(normalized_errors)
      ret = nil
      return ret unless normalized_errors and not normalized_errors.empty?
      rows = normalized_errors.map do |err|
        {
          content: err,
          ref: 'task_error',
          task_id: id()
        }
      end
      Model.create_from_rows(child_model_handle(:task_error), rows, convert: true)
      normalized_errors
    end

    def update_input_attributes!
      # updates ruby task object
      executable_action().get_and_update_attributes!(self)
    end

    def add_internal_guards!(guards)
      # updates ruby task object
      executable_action().add_internal_guards!(guards)
    end

    def reify!
      self[:executable_action] &&= Action::OnNode.create_from_hash(self[:executable_action_type], self[:executable_action], id_handle)
    end

    def ret_command_and_control_adapter_info
      # TODO: stub
      [:node_config, nil]
    end


    private

     def executable_action(opts = {})
       unless @executable_action ||= self[:executable_action]
         fail Error.new('executable_action should not be null') unless opts[:no_error_if_nil]
       end
       @executable_action
     end

    def self.render_group_by_node(task_list)
      return task_list if task_list.size < 2
      ret = nil
      indexed_nodes = {}
      task_list.each do |t|
        if t[:level] == 'top'
          ret = t
        elsif t[:level] == 'node'
          indexed_nodes[t[:node_id]] = t
        end
      end
      task_list.each do |t|
        if t[:level] == 'node'
          ret[:children] << t
        elsif t[:level] == 'component'
          if indexed_nodes[t[:node_id]]
            indexed_nodes[t[:node_id]][:children] << t
          else
            node_task = Task.render_task_on_node(node_id: t[:node_id], node_name: t[:node_name])
            node_task[:children] << t
            ret[:children] << node_task
            indexed_nodes[node_task[:node_id]] = node_task
          end
        end
      end
      ret
    end

    def render_top_task
      { task_id: id(),
        level: 'top',
        type: 'top',
        action_on_failure: self[:action_on_failure],
        children: []
      }
    end

    def render_executable_tasks
      executable_action = executable_action()
      sc = executable_action[:state_change_types]
      common_vals = {
        task_id: id(),
        status: self[:status]
      }
      # order is important
      if sc.include?('create_node') then Task.render_tasks_create_node(executable_action, common_vals)
      elsif sc.include?('install_component') then Task.render_tasks_component_op('install_component', executable_action, common_vals)
      elsif sc.include?('setting') then Task.render_tasks_setting(executable_action, common_vals)
      elsif sc.include?('update_implementation') then Task.render_tasks_component_op('update_implementation', executable_action, common_vals)
      elsif sc.include?('converge_component') then Task.render_tasks_component_op('converge_component', executable_action, common_vals)
      else
        Log.error("do not treat executable tasks of type(s) #{sc.join(',')}")
        nil
      end
    end

    def self.render_task_on_node(node_info)
      { type: 'on_node',
        level: 'node',
        children: []
      }.merge(node_info)
    end

    def self.render_tasks_create_node(executable_action, common_vals)
      node = executable_action[:node]
      task = {
        type: 'create_node',
        level: 'node',
        node_id: node[:id],
        node_name: node[:display_name],
        children: []
      }
      [task.merge(common_vals)]
    end

    def self.render_tasks_component_op(type, executable_action, common_vals)
      node = executable_action[:node]
      executable_action.component_actions().map do |component_action|
        component = component_action[:component]
        cmp_attrs = {
          component_id: component[:id],
          component_name: component[:display_name]
        }
        task = {
          type: type,
          level: 'component',
          node_id: node[:id],
          node_name: node[:display_name],
          component_basic_type: component[:basic_type]
        }
        task.merge!(cmp_attrs)
        task.merge!(common_vals)
        add_attributes_to_component_task!(task, component_action, cmp_attrs)
      end
    end

    def self.render_tasks_setting(executable_action, common_vals)
      node = executable_action[:node]
      executable_action.component_actions().map do |component_action|
        component = component_action[:component]
        cmp_attrs = {
          component_id: component[:id],
          component_name: component[:display_name].gsub(/::/, '_')
        }
        task = {
          type: 'on_component',
          level: 'component',
          node_id: node[:id],
          node_name: node[:display_name],
          component_basic_type: component[:basic_type]
        }
        task.merge!(cmp_attrs)
        task.merge!(common_vals)
        add_attributes_to_component_task!(task, component_action, cmp_attrs)
      end
    end

    def self.add_attributes_to_component_task!(task, component_action, cmp_attrs)
      attributes = component_action[:attributes]
      return task unless attributes
      keep_ids = component_action[:changed_attribute_ids]
      pruned_attrs = attributes.reject do |a|
        a[:hidden] || (keep_ids and not keep_ids.include?(a[:id]))
      end
      flattten_attrs = AttributeComplexType.flatten_attribute_list(pruned_attrs)
      flattten_attrs.each do |a|
        val = a[:attribute_value]
        if val.nil?
          next unless a[:port_type] == 'input' && a[:required]
          val = 'DYNAMICALLY SET'
        end
        attr_task = {
          type: 'setting',
          level: 'attribute',
          attribute_id: a[:id],
          attribute_name: a[:display_name],
          attribute_value: val,
          attribute_data_type: a[:data_type],
          attribute_required: a[:required],
          attribute_dynamic: a[:dynamic]
        }
        attr_task.merge!(cmp_attrs)
        task[:children] ||= []
        task[:children] << attr_task
      end
      task
    end
  end
end
