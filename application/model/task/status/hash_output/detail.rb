module DTK; class Task::Status
  class HashOutput              
    class Detail
      dtk_nested_require('detail', 'executable_action')
      
      def initialize(hash_output, task)
        @hash_output = hash_output
        @task        = task
      end
      
      def self.add_details?(hash_output, task)
        new(hash_output, task).add_details?
      end
      
      def add_details?
        ExecutableAction.add_components_and_actions?(@hash_output, @task)
        set?(:action_results, action_results?())
        set?(:errors, errors?())
        @hash_output
      end
      
      private
      
      def action_results?
        if action_results = @task[:action_results]
          action_results.map { |a| Aux.hash_subset(a, ActionResultFields) }
        end
      end
      ActionResultFields = [:status, :stdout, :stderr, :description]
      
      def errors?
        if errors = @task[:errors]
          # TODO: stubs
          pp [:llllllllllllllllllllll,errors]
          errors
        end
      end
      
      def set?(key, value)
        unless value.nil?
          @hash_output[key] = value
        end
      end
      
    end
  end
end; end
    
