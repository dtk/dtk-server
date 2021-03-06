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
module DTK; class Task::Status
  module TableForm
    class NodeGroupSummary
      def initialize(subtasks)
        @subtasks = subtasks
      end

      def add_summary_info!(ng_table_el, &block_for_subtasks)
        @block_for_subtasks = block_for_subtasks
        if status = ng_table_el[:status]
          case status
           when Type.succeeded
            ng_table_el[:status] = status_when_succeeded()
           when Type.executing
            ng_table_el[:status] = status_when_executing()
           when Type.cancelled
           # no op
           when Type.failed
            ng_table_el[:status] = status_when_failed()
            errors = summarize_errors?()
            ng_table_el[:errors] = errors unless errors.empty?
           else
            Log.error("Unexpected status #{status}")
          end
        end
        ng_table_el
      end

      private

      def status_when_succeeded
        status_with_subtask_size(Type.succeeded)
      end

      def status_when_executing
        status_when_aux(Type.executing)
      end

      def status_when_failed
        status_when_aux(Type.failed)
      end

      def status_when_aux(status)
        st_status_count = subtask_status_count()
        if st_status_count.empty?
          status
        else
          st_status_count.inject('') do |st, (status, count)|
            status_string = status_with_subtask_size(status, count)
            st.empty? ? status_string : "#{st},#{status_string}"
          end
        end
      end

      def status_with_subtask_size(status, count = nil)
        "#{status}(#{(count || subtask_count())})"
      end

      def subtask_count
        @subtasks.size
      end

      def subtask_status_rows
        @subtask_status_rows ||= (@block_for_subtasks && @block_for_subtasks.call()) || []
      end

      def subtask_status_count
        ret = {}
        subtask_status_rows().each do |subtask_table_el|
          if status = subtask_table_el[:status]
            ret[status] ||= 0
            ret[status] += 1
          end
        end
        ret
      end

      def summarize_errors?
        all_errors = []
        subtask_status_rows().each do |st|
          if errors = st[:errors]
            if errors.is_a?(Array)
              all_errors += errors
            else
              all_errors << errors
            end
          end
        end
        summarize_errors(all_errors) unless all_errors.empty?
      end

      def summarize_errors(errors)
        # assuming all fields are the same except :message
        msgs_found = []
        errors.each do |err|
          msg = err[:message]
          if msg && !msg.empty?
            unless msgs_found.include?(msg)
              msgs_found << msg
            end
          end
        end
        if msgs_found.empty?
          errors.first
        else
          summary_msg = (msgs_found.size == 1 ? msgs_found.first : "\n#{ErrIdent}#{msgs_found.join(ErrIdent)}")
          errors.first.merge(message: summary_msg)
        end
      end
      ErrIdent = '  '
    end
  end
end; end