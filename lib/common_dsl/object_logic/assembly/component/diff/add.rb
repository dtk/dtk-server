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
    class Component::Diff
      class Add < CommonDSL::Diff::Element::Add
        def process
          matching_aug_cmp_templates = ::DTK::Component::Template.find_matching_component_templates(assembly_instance, component_name) 
          pp [:matching_aug_cmp_templates, component_name, matching_aug_cmp_templates]
          unless matching_aug_cmp_templates.size == 1
            fail Error, "TODO: DTK-2650: put in error messages to indicate that no or ambiguous module match found"
          end
          aug_cmp_template = matching_aug_cmp_templates.first
          # TODO: use this and node to add component to node
          # node is gotten by looking at qualified_key
          # case on whether assembly or node level
        end 

        private

        def component_name
          relative_distinguished_name
        end

      end
    end
  end
end; end
