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
module Ramaze::Helper
  module TaskHelper
    def cancel_task(top_task_id)
      unless top_task = ::DTK::Task::Hierarchical.get_and_reify(id_handle(top_task_id,:task))
        raise ::DTK::ErrorUsage.new("Task with id '#{top_task_id}' does not exist")
      end
      ::DTK::Workflow.cancel(top_task)
    end

    def most_recent_task_is_executing?(assembly)
      if task = ::DTK::Task.get_top_level_most_recent_task(model_handle(:task), [:eq, :assembly_id, assembly.id()])
        task.has_status?(:executing) && task
      end
    end
  end
end