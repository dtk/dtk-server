module DTK; class Task; class Status
  class StreamForm
    class Element 
      r8_nested_require('element','task_start')
      r8_nested_require('element','task_end')
      r8_nested_require('element','stage')
      r8_nested_require('element','no_results')

      def initialize(type,task=nil)
        @type = type
        @task = task
      end
      private :initialize

      def self.get_task_start_element(top_level_task)
        TaskStart.new(top_level_task)
      end
      
      def self.get_stage_elements(top_level_task, start_index, end_index)
        Stage.elements(top_level_task, start_index, end_index)
      end

      attr_reader :type, :task

      def hash_form
        HashForm.new(self)
      end
      class HashForm < ::Hash
        def initialize(element)
          @task = element.task

          replace(type: element.type)
          add_elements?(:started_at,:display_name)
        end

        def add_elements?(*keys)
          ret = self
          return ret unless @task

          @task.update_obj!(*keys)
          keys.each{|k|self[k] = @task[k]}
          self
        end
      end
    end
  end
end; end; end
