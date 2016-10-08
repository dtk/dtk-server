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
module DTK; class AssemblyModule
  class Component
    class AdHocLink < self
      def self.update(assembly, parsed_adhoc_link_info)
        new(assembly).update(parsed_adhoc_link_info)
      end

      def update(parsed_adhoc_link_info)
        parsed_adhoc_links = parsed_adhoc_link_info.links
        unless  parsed_adhoc_links.size == 1
          fail Error.new("Only implemented #{self}.update when parsed_adhoc_links.size == 1")
        end
        parsed_adhoc_link = parsed_adhoc_links.first

        dep_cmp_template = parsed_adhoc_link_info.dep_component_template
        antec_cmp_template = parsed_adhoc_link_info.antec_component_template

        component_module = dep_cmp_template.get_component_module()
        module_branch = create_module_for_service_instance?(component_module, ret_module_branch: true)

        opts_create_dep = {
          source_attr_pattern: parsed_adhoc_link.attribute_pattern(:source),
          target_attr_pattern: parsed_adhoc_link.attribute_pattern(:target),
          update_dsl: true
        }
        result = create_dependency?(:link, dep_cmp_template, antec_cmp_template, module_branch, opts_create_dep)
        if result[:component_module_updated]
          update_cmp_instances_with_modified_template(component_module, module_branch)
        end
        result
      end
    end
  end
end; end