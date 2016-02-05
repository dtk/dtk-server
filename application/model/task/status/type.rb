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
class DTK::Task::Status
  module Type
    StatusTypes =
        [
         'created',
         'executing',       
         'succeeded',             
         'failed',
         'cancelled',  
         'preconditions_failed'
        ]

    StatusTypes.each do |status|
      class_eval("def self.#{status}(); '#{status}'; end")
      class_eval("def self.has_status_#{status}(task_status); '#{status}' == check_status(task_status); end")
    end

    def self.includes_status?(status_array, status)
      status = check_status(status)
      !!status_array.find { |s| send(check_status(s)) == status } 
    end

    def self.task_has_status?(task, status)
      status = check_status(status)
      task_status = task.get_field?(:status)
      task_status and task_status.to_s == status
    end


    def self.is_workflow_ending_status?(status)
      ['failed', 'cancelled', 'preconditions_failed'].include?(check_status(status))
    end

    private

    def self.check_status(status)
      return nil unless status
      status = status.to_s
      unless StatusTypes.include?(status)
        fail Error.new("Illegal status '#{status}'")
      end
      status
    end
  end
end