module DTK; class Task
  module ActionResults
    module Mixin
      def add_action_results(result,action)
        unless action_results = result[:data][:data]['results']
          Log.error_pp(["Unexpected that result[:data][:data][:output] is nil",result])
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
