module DTK; class Task
  module ActionResults
    module Mixin
      def add_action_results(result, action)
        unless action_results = CommandAndControl.node_action_results(result, action)
          Log.error_pp(['Unexpected that cannot find data in results:', result])
          return
        end
        # TODO: using task logs for storage; might introduce a new table
        rows = []
        action_results.each_with_index do |action_result, pos|
          label = QualifiedIndex.string_form(self)
          el = {
            content: action_result,
            ref: "task_log-#{label}--#{pos}",
            task_id: id(),
            display_name: label,
            position: pos
          }
          rows << el
        end
        Model.create_from_rows(child_model_handle(:task_log), rows, convert: true)
      end
    end

    def self.get_action_detail(assembly, action_label, _opts = {})
      ret = ''
      task_mh = assembly.model_handle(:task)
      unless task = Task.get_top_level_most_recent_task(task_mh, [:eq, :assembly_id, assembly.id()])
        fail ErrorUsage.new("No tasks found for '#{assembly.display_name_print_form()}'")
      end
      # TODO: more efficienct would be to be able to do withone call and filter on action_label in get_all_subtasks_with_logs()
      subtasks = task.get_all_subtasks_with_logs()
      task_log_mh = task_mh.createMH(:task_log)
      sp_hash = {
        cols: [:id, :display_name, :content, :position],
        filter: [:and, [:eq, :display_name, action_label], [:oneof, :task_id, subtasks.map(&:id)]]
      }

      log_entries = Model.get_objs(task_log_mh, sp_hash)
      if log_entries.empty?
        fail ErrorUsage.new("Task action with identifier '#{action_label}' does not exist for this service instance.")
      end
      ordered_log_entries = log_entries.sort { |a, b| (a[:position] || 0) <=> (b[:position] || 0) }
      ordered_log_entries.each do |l|
        content     = l[:content]
        description = parse_description(content[:description])
        ret << "==============================================================\n"
        ret << "#{description} \n"
        ret << "STATUS: #{content[:status]} \n"
        ret << "STDOUT: #{content[:stdout]}\n\n" if content[:stdout] && !content[:stdout].empty?
        ret << "STDERR: #{content[:stderr]} \n" if content[:stderr] && !content[:stderr].empty?
      end
      ret
    end

    private

    def self.parse_description(description)
      if match = description.match(/^(create )(.*)/)
        return "ADD: #{match[2]}"
      else
        "RUN: #{description}"
      end
    end
  end
end; end
