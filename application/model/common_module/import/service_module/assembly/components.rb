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
module DTK
  class CommonModule::Import::ServiceModule
    module Assembly
      module Components
        include ServiceDSLCommonMixin

        def self.db_update_hash(container_idh, parsed_components, component_module_refs, opts = {})
          cmps_with_titles = []
          ret = parsed_components.inject(DBUpdateHash.new) do |h, parsed_component| 
            component_info = component_info(parsed_component)
            add_attribute_overrides!(component_info, parsed_component)
            if title = component_info[:component_title]
              cmps_with_titles << { cmp_ref: component_info, cmp_title: title }
            end
            h.merge(component_info[:ref] => component_info)
          end

          component_module_refs.set_matching_component_template_info?(ret.values, donot_set_component_templates: true, set_namespace: true)
          CommonModule::Import::ServiceModule.set_attribute_template_ids!(ret, container_idh)
          CommonModule::Import::ServiceModule.add_title_attribute_overrides!(cmps_with_titles, container_idh)
          ret
        end

        private

        def self.component_info(parsed_component)
          info    = InternalForm.component_ref_info(parsed_component.req(:Name))
          type    = info[:component_type]
          title   = info[:title]
          version = info[:version]

          ret = {
            ref: ComponentRef.ref(type, title),
            display_name:  ComponentRef.display_name(type, title),
            component_type: type
          }
          ret.merge!(version: version, has_override_version: true) if version 
          ret.merge!(component_title: title) if title
          ret
        end

        def self.add_attribute_overrides!(component_info, parsed_component)
          (parsed_component.val(:Attributes) || []).each do |parsed_attribute|
            (component_info[:attribute_override] ||= {}).merge!(attribute_override(parsed_attribute))
          end
        end

        def self.attribute_override(parsed_attribute)
          name  = parsed_attribute.req(:Name) 
          value = parsed_attribute.val(:Value)
          { name => {display_name: name, attribute_value: value } }
        end

      end
    end
  end
end