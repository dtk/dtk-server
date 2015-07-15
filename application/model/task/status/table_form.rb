module DTK; class Task; class Status
  module TableForm
    DURATION_ACCURACY = 1

    r8_nested_require('table_form', 'node_group_summary')
    module Mixin
      def status_table_form(opts)
        TableForm.status_table_form_top(self, opts)
      end
    end

    def self.status(task_structure, opts = {})
      task_structure.status_table_form(opts)
    end

    def self.status_table_form_top(task, opts)
      status_table_form(task, opts)
    end

    private

    def self.status_table_form(task, opts, level = 1, ndx_errors = nil)
      ret = []
      task.set_and_return_types!()
      el = task.hash_subset(:started_at, :ended_at)

      duration = el[:ended_at] - el[:started_at] if el[:ended_at] && el[:started_at]
      el[:duration] = "#{duration.round(DURATION_ACCURACY)}s" if duration

      el[:status] = task[:status] unless task.has_status?(:created)
      el[:id] = task[:id]
      # For ALdin 'type' needs to be computed depeidningon whether it is a create node, craeet component or action
      # also can be different depending on whether it is a group
      qualified_index = QualifiedIndex.string_form(task)
      # for space after qualified index if not empty
      qualified_index += ' ' unless qualified_index.empty?
      type = element_type(task, level)
      # putting idents in
      el[:type]  = "#{' ' * (2 * (level - 1))}#{qualified_index}#{type}"
      el[:index], el[:sub_index] = qualified_index.split('.').collect(&:to_i)
      ndx_errors ||= task.get_ndx_errors()
      if ndx_errors[task[:id]]
        el[:errors] = format_errors(ndx_errors[task[:id]])
      end

      # TODO: on 7/14/2015 does not look like el[:logs] is being displayed. 
      #       Also format_logs is just ignoring context and just leaving msg hat theer are results
      if task_logs = task.get_logs?
        el[:logs] = format_logs(task_logs)
      end

      ea = nil
      if level == 1
        # no op
      else
        ea = task[:executable_action]
        case task[:executable_action_type]
          when 'ConfigNode'
            el.merge!(Task::Action::ConfigNode.status(ea, opts)) if ea
          when 'CreateNode'
            el.merge!(Task::Action::CreateNode.status(ea, opts)) if ea
          when 'PowerOnNode'
            el.merge!(Task::Action::PowerOnNode.status(ea, opts)) if ea
          when 'InstallAgent'
          el.merge!(Task::Action::InstallAgent.status(ea, opts)) if ea
          when 'ExecuteSmoketest'
            el.merge!(Task::Action::ExecuteSmoketest.status(ea, opts)) if ea
          end
      end
      ret << el

      subtasks = task.subtasks()
      num_subtasks = subtasks.size
      if num_subtasks > 0
        if opts[:summarize_node_groups] && (ea && ea[:node].is_node_group?())
          NodeGroupSummary.new(subtasks).add_summary_info!(el) do
            subtasks.flat_map { |st| status_table_form(st, opts, level + 1) }
          end
        else
          ret += subtasks.sort { |a, b| (a[:position] || 0) <=> (b[:position] || 0) }.flat_map do |st|
            status_table_form(st, opts, level + 1, ndx_errors)
          end
        end
      end
      ret
    end

    def self.format_errors(errors)
      ret = nil
      errors.each do |error|
        if ret
          ret[:message] << "\n\n"
        else
          ret = { message: '' }
        end

        if error.is_a? String
          error, temp = {}, error
          error[:message] = temp
        end

        error_msg = (error[:component] ? "Component #{error[:component].gsub('__', '::')}: " : '')
        error_msg << (error[:message] || 'error')
        ret[:message] << error_msg
        ret[:type] = error[:type]
      end
      ret
    end

    def self.format_logs(logs)
      ret = nil
      message = ''

      logs.each do |log|
        unless ret
          ret = { message: '' }
        end

        if log.is_a? String
          log, temp = {}, log
          log[:message] = temp
        end

        if message.empty?
          message << ("To see more detail about specific task action use 'task-action-detail <TASK NUMBER>'\n")
          ret[:message] << message
          ret[:label]   = log[:label]
          ret[:type]    = log[:type]
        end
      end

      ret
    end

    def self.element_type(task, level)
      if level == 1
        task[:display_name]
      elsif type = task[:type]
        node = (task[:executable_action] || {})[:node]
        config_agent = task.get_config_agent_type(nil, no_error_if_nil: true)

        if config_agent == 'dtk_provider'
          if node && node.is_node_group?()
            type = 'nodegroup actions'
          else
            type = 'action'
          end
        end

        if ['configure_node', 'create_node'].include?(type)
          type = "#{type}group" if node && node.is_node_group?()
        end

        type
      else
        task[:display_name] || 'top'
      end
    end
  end
end; end; end
