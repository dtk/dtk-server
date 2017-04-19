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
    class ComponentLink::Diff
      class Add < CommonDSL::Diff::Element::Add
        def process(result, opts = {})
          assembly_instance    = service_instance.assembly_instance
          augmented_components = assembly_instance.get_augmented_components
          base_component_name  = CommonDSL::Diff::QualifiedKey.parent_component_name?(qualified_key, include_node: true)
          dep_component_name   = parse_object
          dependency_name      = relative_distinguished_name

          base_component, dependent_component = ret_matching_components(augmented_components, base_component_name, dep_component_name)

          if base_component && dependent_component
            input_cmp_idh    = base_component.id_handle
            output_cmp_idh   = dependent_component.id_handle
            service_link_idh = assembly_instance.add_service_link?(input_cmp_idh, output_cmp_idh, dependency_name: dependency_name)
          end

          result.add_item_to_update(:assembly)
        end
        
        private
        
        def ret_matching_components(aug_components, base_cmp, dependent_cmp)
          base_node         = 'assembly_wide_node'
          matching_base_cmp = nil
          
          dependent_node   = 'assembly_wide_node'
          matching_dep_cmp = nil
          dependent_cmp    = dependent_cmp[:value] if dependent_cmp.is_a?(Hash) && dependent_cmp.has_key?(:value)

          base_node, base_cmp = base_cmp.split('/') if base_cmp.include?('/')
          dependent_node, dependent_cmp = dependent_cmp.split('/') if dependent_cmp.include?('/')

          aug_components.each do |aug_cmp|
            break if matching_base_cmp && matching_dep_cmp

            cmp_type = aug_cmp[:display_name].gsub('__', '::')
            cmp_node = aug_cmp[:node][:display_name]

            if cmp_type.eql?(base_cmp) && base_node.eql?(cmp_node)
              matching_base_cmp = aug_cmp
            end

            if cmp_type.eql?(dependent_cmp) && dependent_node.eql?(cmp_node)
              matching_dep_cmp = aug_cmp
            end
          end

          return [matching_base_cmp, matching_dep_cmp]
        end
      end
    end
  end
end; end
