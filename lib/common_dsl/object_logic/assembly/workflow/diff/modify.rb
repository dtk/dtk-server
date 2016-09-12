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
  class ObjectLogic::Assembly
    class Workflow::Diff
      class Modify < CommonDSL::Diff::Element::Modify
        def process(result)
          # TODO: parse here or netter in dsl pasring
          # parse_error = Task::Template::ConfigComponents.find_parse_error?(new_workflow, assembly: assembly_instance, keys_are_in_symbol_form: true)
          # even if there is a parse error savings so user can go back and update what user justed edited
          Task::Template.update_from_serialized_content(assembly_instance.id_handle, new_workflow, task_action_name)
          nil
        end

        private

        def new_workflow
          @new_val
        end


        MAPPING_TO_TAKS_ACTION_NAMES = {
          'create' => nil 
        }
        def task_action_name
          workflow_name = name
          MAPPING_TO_TAKS_ACTION_NAMES.has_key?(workflow_name) ?  MAPPING_TO_TAKS_ACTION_NAMES[workflow_name] : workflow_name
        end

      end
    end
  end
end; end
