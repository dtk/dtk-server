module DTK; class Task::Status::StreamForm::Element
  class Stage
    module Detail
      def self.add_detail!(stage_elements, opts = {})
        ret = stage_elements
        return ret if stage_elements.empty?
        
        detail = opts[:element_detail]||{}
        if detail[:action_results]
          action_result_tasks = ActionResultTask.find_and_expand(stage_elements.map{|el|el.task})
        end
        ret
      end

      module ActionResultTask
        def self.find_and_expand(tasks)
          #stub
          pp :ActionResultTask
        end

      end
    end
  end
end; end
