module DTK; class Task::Status
  module TableForm
    r8_nested_require('table_form','node_group_summary')
    module Mixin
      def status_table_form(opts)
        TableForm.status_table_form_top(self,opts)
      end
    end

    def self.status(task_structure,opts={})
      task_structure.status_table_form(opts)
    end

    def self.status_table_form_top(task,opts)
      status_table_form(task,opts)
    end

   private
    def self.status_table_form(task,opts,level=1,ndx_errors=nil)
      ret = Array.new
      task.set_and_return_types!()
      el = task.hash_subset(:started_at,:ended_at)
      el[:status] = task[:status] unless task[:status] == 'created'
      el[:id] = task[:id]
      type = element_type(task,level)
      # putting idents in
      el[:type] = "#{' '*(2*(level-1))}#{type}"
      ndx_errors ||= task.get_ndx_errors()
      if ndx_errors[task[:id]]
        el[:errors] = format_errors(ndx_errors[task[:id]])
      end

      task_logs = task.get_logs()
      if task_logs && task_logs[task[:id]]
        el[:logs] = format_logs(task_logs[task[:id]])
      end
        
      ea = nil
      if level == 1
        # no op
      else
        ea = task[:executable_action]
        case task[:executable_action_type]
          when "ConfigNode" 
            el.merge!(Task::Action::ConfigNode.status(ea,opts)) if ea
          when "CreateNode" 
            el.merge!(Task::Action::CreateNode.status(ea,opts)) if ea
          when "PowerOnNode"
            el.merge!(Task::Action::PowerOnNode.status(ea,opts)) if ea
          when "InstallAgent"
          el.merge!(Task::Action::InstallAgent.status(ea,opts)) if ea
          when "ExecuteSmoketest"
            el.merge!(Task::Action::ExecuteSmoketest.status(ea,opts)) if ea
          end
      end
      ret << el

      subtasks = task.subtasks()
      num_subtasks = subtasks.size
      if num_subtasks > 0
        if opts[:summarize_node_groups] and (ea and ea[:node].is_node_group?())
          NodeGroupSummary.new(subtasks).add_summary_info!(el) do
            subtasks.map{|st|status_table_form(st,opts,level+1)}.flatten(1)
          end
        else
          ret += subtasks.sort{|a,b| (a[:position]||0) <=> (b[:position]||0)}.map do |st|
            status_table_form(st,opts,level+1,ndx_errors)
          end.flatten(1)
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
          ret = {:message => String.new}
        end
        
        if error.is_a? String
          error,temp = {},error
          error[:message] = temp
        end
        
        error_msg = (error[:component] ? "Component #{error[:component].gsub("__","::")}: " : "")
        error_msg << (error[:message]||"error")
        ret[:message] << error_msg
        ret[:type] = error[:type]
      end
      ret
    end

    def self.format_logs(logs)
      ret = nil

      logs.each do |log|
        if ret
          ret[:message] << "\n\n"
        else
          ret = {:message => String.new}
        end

        if log.is_a? String
          log,temp = {},log
          log[:message] = temp
        end

        ret[:message] << ("To see more detail about specific task action use 'task-action-detail <ACTION>'")
        ret[:label]   = log[:label]
        ret[:type]    = log[:type]
      end

      ret
    end

    def self.element_type(task,level)
      if level == 1
        task[:display_name] 
      elsif type = task[:type]
        if ['configure_node','create_node'].include?(type)
          if node = (task[:executable_action]||{})[:node]
            type = "#{type}group" if node.is_node_group?()
          end
        end
        type
      else
        task[:display_name]|| "top"
      end
    end
  end
end; end
