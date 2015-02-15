module DTK; class Task
  module ActionResults
    r8_nested_require('action_results','label')
    module Mixin
      def add_action_results(result,action,top_task)
        unless action_results = result[:data][:data][:output]
          Log.error_pp(["Unexpected that result[:data][:data][:output] is nil",result])
        end
        # TODO: using task logs for storage; might introduce a new table
        rows = action_results.map do |action_result|
          label = Label.label(action,top_task)
          {
            :content      => action_result,
            :ref          => "task_log-#{label}",
            :task_id      => id(),
            :display_name => label
          }
        end
        Model.create_from_rows(child_model_handle(:task_log),rows,{:convert => true})
      end

      # These are invoked on top_task
      # This is described as 'first_index' because with node groups we have first_index.node_group_index
      def first_index_action_count()
        @first_index_action_count ||= 0
      end
      def bump_first_index_action_count!()
      @first_index_action_count = first_index_action_count() + 1
      end
    end
  end
end; end
