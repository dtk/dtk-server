module DTK; class Task
  module ActionResults
    module Mixin
      def add_action_results(result,top_task)
        unless action_results = result[:data][:data][:output]
          Log.error_pp(["Unexpected that result[:data][:data][:output] is nil",result])
        end
        # TODO: using task logs for storage; might introduce a new table
        rows = action_results.map do |action_result|
          action_count = top_task.bump_action_count!()
          {
            :content      => action_result,
            :ref          => "task_log#{action_count.to_s}",
            :task_id      => id(),
            :display_name => action_count.to_s
          }
        end
        Model.create_from_rows(child_model_handle(:task_log),rows,{:convert => true})
      end

      def action_count()
        @action_count ||= 0
      end
      def bump_action_count!()
        @action_count = action_count() + 1
      end

    end
  end
end; end
