module DTK; class Task; class Status
  class StreamForm
    class Element 
      r8_nested_require('element','task_start')
      r8_nested_require('element','stage')
      def initialize(type,task)
        @type = type
        @task = task
      end
      private :initialize

      def hash_form
        {
          type:       @type,
          started_at: @task.get_field?(:started_at)
        }
      end

      def self.get_task_start_element(top_level_task)
        TaskStart.new(top_level_task)
      end
      
      def self.get_stage_elements(top_level_task,start_index,end_index)
        Stage.elements(top_level_task,start_index,end_index)
      end
    end
  end
end; end; end
