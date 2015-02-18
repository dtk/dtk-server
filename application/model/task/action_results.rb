module DTK; class Task
  module ActionResults
    module Mixin
      def add_action_results(result,action)
        unless action_results = CommandAndControl.node_action_results(result,action)
          Log.error_pp(["Unexpected that cannot find data in results:",result])
          return
        end
        # TODO: using task logs for storage; might introduce a new table
        rows = action_results.map do |action_result|
          label = QualifiedIndex.string_form(self)
          {
            :content      => action_result,
            :ref          => "task_log-#{label}",
            :task_id      => id(),
            :display_name => label
          }
        end
        Model.create_from_rows(child_model_handle(:task_log),rows,{:convert => true})
      end

    end
  end
end; end
