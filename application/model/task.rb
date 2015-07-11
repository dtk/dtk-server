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
    include Hierarchical::Mixin
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

    def is_status?(status)
      self[:status] == status || self[:subtasks].find { |subtask| subtask[:status] == status }
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

    def update_task_subtask_status(status, result)
      self[:subtasks].each do |subtask|
        if subtask[:subtasks]
          subtask[:subtasks].each do |child_subtask|
            child_subtask.update_at_task_completion(status, result)
          end
        end
        subtask.update_at_task_completion(status, result)
      end
      self.update_at_task_completion(status, result)
    end

    def update_at_task_completion(status, result)
      update_hash = {
        status: status,
        result: result,
        ended_at: Aux.now_time_stamp()
      }
      update(update_hash)
    end

    def update_at_task_start(_opts = {})
      update(status: 'executing', started_at: Aux.now_time_stamp())
    end

    def update_when_failed_preconditions(_failed_antecedent_tasks)
      ts = Aux.now_time_stamp()
      update(status: 'preconditions_failed', started_at: ts, ended_at: ts)
      # TODO: put in context about failure in errors
    end

    # TODO: update and update_parents can be cleaned up because halfway between update and update_object!
    # this updates self, which is leaf node, plus all parents
    def update(update_hash, opts = {})
      super(update_hash)
      unless opts[:dont_update_parents] || (update_hash.keys & [:status, :started_at, :ended_at]).empty?
        if task_id = update_object!(:task_id)[:task_id]
          update_parents(update_hash.merge(task_id: task_id))
        end
      end
    end

    # updates parent fields that are fn of children (:status,:started_at,:ended_at)
    def update_parents(child_hash)
      parent = id_handle.createIDH(id: child_hash[:task_id]).create_object().update_object!(:status, :started_at, :ended_at, :children_status)
      key = id().to_s.to_sym #TODO: look at avoiding this by having translation of json not make num keys into symbols
      children_status = (parent[:children_status] || {}).merge!(key => child_hash[:status])

      parent_updates = { children_status: children_status }
      # compute parent start time
      unless parent[:started_at] || child_hash[:started_at].nil?
        parent_updates.merge!(started_at: child_hash[:started_at])
      end

      # compute new parent status
      subtask_status_array = children_status.values
      parent_status =
        if subtask_status_array.include?('executing') then 'executing'
        elsif subtask_status_array.include?('failed') then 'failed'
        elsif subtask_status_array.include?('cancelled') then 'cancelled'
        elsif not subtask_status_array.find { |s| s != 'succeeded' } then 'succeeded' #all succeeded
        else 'executing' #if reach here must be some created and some finished
       end
      unless parent_status == parent[:status]
        parent_updates.merge!(status: parent_status)
        # compute parent end time which can only change if parent changed to "failed" or "succeeded"
        if ['failed', 'succeeded'].include?(parent_status) && child_hash[:ended_at]
          parent_updates.merge!(ended_at: child_hash[:ended_at])
        end
      end

      dont_update_parents = (parent_updates.keys - [:children_status]).empty?
      parent.update(parent_updates, dont_update_parents: dont_update_parents)
    end
    private :update_parents

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

    # saves hirerachical structure to db and returns task with top level and subtask ids filled out
    def save_and_add_ids
      save!()
      # TODO: this is simple but expensive way to get all teh embedded task ids filled out
      # can replace with targeted method that does just this
      Hierarchical.get_and_reify(id_handle())
    end

    # persists to db this and its sub tasks
    def save!
     # no op if saved already as detected by whether has an id
     return nil if id()
      set_positions!()
      # for db access efficiency implement into two phases: 1 - save all subtasks w/o ids, then put in ids
      unrolled_tasks = unroll_tasks()
      rows = unrolled_tasks.map do |hash_row|
        executable_action = hash_row[:executable_action]
        row = {
          display_name: hash_row[:display_name] || "task#{hash_row[:position]}",
          ref: "task#{hash_row[:position]}",
          executable_action_type: executable_action ? Aux.demodulize(executable_action.class.to_s) : nil,
          executable_action: executable_action
        }
        cols = [:status, :result, :action_on_failure, :position, :temporal_order, :commit_message]
        cols.each { |col| row.merge!(col => hash_row[col]) }
        [:assembly_id, :node_id, :target_id].each do |col|
          row[col] = hash_row[col] || SQL::ColRef.null_id
        end
        row
      end
      new_idhs = Model.create_from_rows(model_handle, rows, convert: true, do_not_update_info_table: true)
      unrolled_tasks.each_with_index { |task, i| task.set_id_handle(new_idhs[i]) }

      # set parent relationship and use to set task_id (subtask parent) and children_status
      par_rel_rows_for_id_info = set_and_ret_parents_and_children_status!()
      par_rel_rows_for_task = par_rel_rows_for_id_info.map { |r| { id: r[:id], task_id: r[:parent_id], children_status: r[:children_status] } }

      Model.update_from_rows(model_handle, par_rel_rows_for_task) unless par_rel_rows_for_task.empty?
      IDInfoTable.update_instances(model_handle, par_rel_rows_for_id_info)
    end

    def subtasks
      self[:subtasks] || []
    end

    # for special tasks that have component actions
    def component_actions
      if executable_action().is_a?(Action::ConfigNode)
        action = executable_action()
        action.component_actions().map { |ca| action[:node] ? ca.merge(node: action[:node]) : ca }
      else
        subtasks.map(&:component_actions).flatten
      end
    end

    def node_level_actions
      if executable_action().is_a?(Action::NodeLevel)
        action = executable_action()
        return action.component_actions().map { |ca| action[:node] ? ca.merge(node: action[:node]) : ca }
      else
        subtasks.map(&:node_level_actions).flatten
      end
    end

    def add_subtask_from_hash(hash)
      defaults = { status: 'created', action_on_failure: 'abort' }
      new_subtask = Task.new(defaults.merge(hash), c)
      add_subtask(new_subtask)
    end

    def add_subtask(new_subtask)
      (self[:subtasks] ||= []) << new_subtask
      new_subtask
    end

    def add_subtasks(new_subtasks)
      new_subtasks.each { |new_subtask| (self[:subtasks] ||= []) << new_subtask }
      self
    end

    def set_positions!
      self[:position] ||= 1
      return nil if subtasks.empty?
      subtasks.each_with_index do |e, i|
        e[:position] = i + 1
        e.set_positions!()
      end
    end

    def set_and_ret_parents_and_children_status!(parent_id = nil)
      self[:task_id] = parent_id
      id = id()
      if subtasks.empty?
        [parent_id: parent_id, id: id, children_status: nil]
      else
        recursive_subtasks = subtasks.map { |st| st.set_and_ret_parents_and_children_status!(id) }.flatten
        children_status = subtasks.inject({}) { |h, st| h.merge(st.id() => 'created') }
        [parent_id: parent_id, id: id, children_status: children_status] + recursive_subtasks
      end
    end

    def unroll_tasks
      [self] + subtasks.map(&:unroll_tasks).flatten
    end

    #### for rending tasks

    public

    def render_form
      # may be different forms; this is one that is organized by node_group, node, component, attribute
      task_list = render_form_flat(true)
      # TODO: not yet teating node_group
      Task.render_group_by_node(task_list)
    end

    protected

     # protected, not private, because of recursive call
     def render_form_flat(top = false)
      # prune out all (sub)tasks except for top and  executable
      return render_executable_tasks() if executable_action(no_error_if_nil: true)
      (top ? [render_top_task()] : []) + subtasks.map(&:render_form_flat).flatten
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
