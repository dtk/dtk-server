#
# Copyright (C) 2010-2017 dtk contributors
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
module DTK; class Assembly::Instance
  module DeleteByPath
    module Actions
      def self.delete(service_instance, params, opts = {})
        task_action          = params.last
        service_instance_idh = service_instance.id_handle

        if Task::Template.get_matching_task_template?(service_instance_idh, task_action)
          Task::Template.delete_task_template?(service_instance_idh, task_action)
        else
          fail ErrorUsage, "Action '#{task_action}' does not exist"
        end
      end
    end
  end
end; end