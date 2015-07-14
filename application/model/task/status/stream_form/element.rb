module DTK; class Task; class Status
  class StreamForm
    class Element 
      r8_nested_require('element', 'hash_form') # This must be first
      r8_nested_require('element', 'task_start')
      r8_nested_require('element', 'task_end')
      r8_nested_require('element', 'stage')
      r8_nested_require('element', 'no_results')

      def initialize(type, task = nil)
        @type = type
        @task = task
      end
      private :initialize

      attr_reader :type, :task
      def self.get_task_start_element(top_level_task)
        TaskStart.new(top_level_task)
      end
      
      def self.get_stage_elements(top_level_task, start_index, end_index, opts={})
        Stage.elements(top_level_task, start_index, end_index, opts)
      end

      def hash_form
        self.class::HashForm.new(self)
      end
    end
  end
end; end; end

