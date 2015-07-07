module DTK; class Task
  class Status
    class StreamForm
      r8_nested_require('stream_form','element')
      def self.status(top_level_task,opts={})
        ret = Array.new
        start_index = opts[:start_index]
        end_index   = opts[:end_index]
        if start_index == '0' and end_index == '0'
          ret << Element::TaskStart.new(top_level_task).hash_form()
        else
          raise Error.new("not treated")
        end
        ret
      end
    end
  end
end; end
