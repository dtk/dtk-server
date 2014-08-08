module DTK; class Task::Status
  module TableForm
    class NodeGroupSummary
      def initialize(subtasks)
        @subtasks = subtasks
      end
      def add_summary_info!(ng_table_el,&block_for_subtasks)
        @block_for_subtasks = block_for_subtasks
        if status = ng_table_el[:status]
          case status 
           when "succeeded"
            ng_table_el[:status] = status_when_succeeded() 
           when "executing"
            ng_table_el[:status] = status_when_executing() 
           when "cancelled"
            # no op
           when "failed"
            Log.error("write code for failed")
           else
            Log.error("Unexpected status #{status}")
          end
        end
        ng_table_el
      end
     private
      def status_when_succeeded()
        status_with_subtask_size("succeeded")
      end
      def status_when_executing()
        st_status_count = subtask_status_count()
        if st_status_count.empty?
          "executing"
        else
          st_status_count.inject("") do |st,(status,count)|
            "#{st},#{status_with_subtask_size(status,count)}"
          end
        end
      end

      def status_with_subtask_size(status,count=nil)
        "#{status}(#{(count||subtask_count()).to_s})"
      end
      def subtask_count()
        @subtasks.size
      end
      def subtask_status_count()
        subtask_status =  (@block_for_subtasks && @block_for_subtasks.call())||[]
        ret = Hash.new
        subtask_status.each do |status|
          ret[status] ||= 0
          ret[status] += 1
        end
        ret
      end
    end
  end
end; end
