#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class Task
  class Status
    class StreamForm
      r8_nested_require('stream_form', 'task_start')
      r8_nested_require('stream_form', 'task_end')
      r8_nested_require('stream_form', 'stage')
      r8_nested_require('stream_form', 'no_results')

      def initialize(type, task = nil)
        @type = type
        @task = task
      end
      private :initialize

      attr_reader :task

      def self.status(top_level_task, opts = {})
        ret = []
        start_index = integer(opts[:start_index], :start_index)
        end_index   = integer(opts[:end_index], :end_index)

        if start_index == 0 && end_index == 0
          ret << TaskStart.new(top_level_task).hash_output()
        elsif start_index <= end_index
          opts_stage = Aux.hash_subset(opts, [:element_detail, :wait_for])
          ret += Stage.elements(top_level_task, start_index, end_index, opts_stage).map(&:hash_output)
        else
          fail ErrorUsage.new("start_index (#{start_index} must be less than or equal to end_index (#{end_index})")
        end
        ret
      end

      def hash_output
        HashOutput.new(@type, @task, hash_output_opts())
      end

      private

      # This can be overwritten
      def hash_output_opts
        {}
      end

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