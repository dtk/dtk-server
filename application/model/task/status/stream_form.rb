module DTK; class Task
  class Status
    class StreamForm
      r8_nested_require('stream_form', 'element')
      def self.status(top_level_task, opts = {})
        ret = []
        start_index = integer(opts[:start_index], :start_index)
        end_index   = integer(opts[:end_index], :end_index)
        if start_index == 0 && end_index == 0
          ret << Element.get_task_start_element(top_level_task).hash_form()
        elsif start_index <= end_index
          opts_stage = Aux.hash_subset(opts,[:element_detail])
          ret += Element.get_stage_elements(top_level_task, start_index, end_index, opts_stage).map(&:hash_form)
        else
          raise ErrorUsage.new("start_index (#{start_index} must be less than or equal to end_index (#{end_index})")
        end
        ret
      end

      private

      def self.integer(index, type)
        integer?(index) || fail(ErrorUsage.new("#{type} should be an integer; its value is: #{index}"))
      end
      def self.integer?(index)
        if index =~ /^[0-9]+$/
          index.to_i
        end
      end
    end
  end
end; end
