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
# TODO: DTK-3366; this file should be removed
module DTK; class AssemblyModule
  class Component
    class Get < self
      module Mixin
        def get_branch_template(module_branch, cmp_template)
          sp_hash = {
            cols: [:id, :group_id, :display_name, :component_type],
            filter: [:and, [:eq, :module_branch_id, module_branch.id()],
                     [:eq, :type, 'template'],
                     [:eq, :node_node_id, nil],
                     [:eq, :component_type, cmp_template.get_field?(:component_type)]]
          }
          Model.get_obj(cmp_template.model_handle(), sp_hash) || fail(Error.new('Unexpected that branch_cmp_template is nil'))
        end
            
        def get_applicable_component_instances(component_module)
          assembly_id = @assembly.id()
          component_module.get_associated_component_instances().select do |cmp|
            cmp[:assembly_id] == assembly_id
          end
        end
      end

    end
  end
end; end
