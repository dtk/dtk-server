module DTK; class Task; class Status
  class StreamForm; class Element
    class Stage < self
      def initialize(task)
        super(:stage,task)
      end

      def self.elements(top_level_task,start_stage,end_stage)
        tasks = top_level_task.get_stages(start_stage,end_stage)
        [new(top_level_task)]
      end
    
    end
  end; end
end; end; end
