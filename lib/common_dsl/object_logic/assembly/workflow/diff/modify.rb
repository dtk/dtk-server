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
          # parse_error = Task::Template::ConfigComponents.find_parse_error?(hash_content, assembly: @assembly, keys_are_in_symbol_form: true)
          # even if there is a parse error savings so user can go back and update what user justed edited
           Task::Template.create_or_update_from_serialized_content?(@assembly.id_handle(), hash_content, @task_action)
nil
        end

      end
    end
  end
end; end
