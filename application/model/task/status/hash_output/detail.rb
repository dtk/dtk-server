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
          ret = action_results.map do |a| 
            Aux.hash_subset(a, ActionResultFields) 
          end.compact
          ret.empty? ? nil : ret
        end
      end
      ActionResultFields = [:status, :stdout, :stderr, :description]
      
      def errors?
        if errors = @task[:errors]
          ret = errors.map do |e|
            if e.kind_of?(String)
              { message: e }
            elsif e.kind_of?(Hash)
              err_hash = Aux.hash_subset(e, ErrorFields)
              err_hash.empty? ? nil : err_hash
            end
          end.compact
          ret.empty? ? nil : ret
        end
      end
      ErrorFields = [:message, :type]

      def set?(key, value)
        unless value.nil?
          @hash_output[key] = value
        end
      end
      
    end
  end
end; end
    
