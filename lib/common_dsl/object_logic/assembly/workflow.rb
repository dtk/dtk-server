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
module DTK; module CommonDSL
  module ObjectLogic
    class Assembly
      class Workflow < Generate::ContentInput::Hash
        def initialize(workflow_name, assembly_instance)
          super()
          @workflow_name     = workflow_name
          @assembly_instance = assembly_instance
        end
        private :initialize

        def self.generate_content_input(assembly_instance)
          # TODO: DTK-2651 need to get more than the create workflow
          workflow_names = ['create']
          workflow_names.inject(ObjectLogic.new_content_input_hash) do |h, workflow_name| 
            h.merge(workflow_name => new(workflow_name, assembly_instance).generate_content_input!)
          end
        end

        def generate_content_input!
          Task::Template::ConfigComponents.get_or_generate_template_content(:assembly, @assembly_instance, task_action: @workflow_name).serialization_form
        end
      end
    end
  end
end; end
