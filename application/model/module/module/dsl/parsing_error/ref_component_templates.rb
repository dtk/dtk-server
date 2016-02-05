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
  class ModuleDSL
    class ParsingError
      class RefComponentTemplates < self
        def initialize(ref_cmp_templates)
          super(err_msg(ref_cmp_templates))
          @ref_cmp_templates = ref_cmp_templates
        end

        private

        def err_msg(ref_cmp_templates)
          msgs_per_cmp_template = msgs_per_cmp_template(ref_cmp_templates)
          ident = '    '
          ref_errors = ident + msgs_per_cmp_template.join("\n#{ident}")
          size = msgs_per_cmp_template.size
          what = (size == 1 ? 'component' : 'components')
          "The result if the changes were made would be the following #{what}\n  would be deleted while still being referenced by existing assembly templates:\n#{ref_errors}"
        end

        def msgs_per_cmp_template(ref_cmp_templates)
          ref_cmp_templates.flat_map do |ref_cmp_template|
            cmp_tmpl_name = ref_cmp_template[:component_template].display_name_print_form
            assembly_templates = ref_cmp_template[:assembly_templates]
            Assembly::Template.augment_with_namespaces!(assembly_templates)
            assembly_templates.map do |assembly_template|
              assembly_template_name = Assembly::Template.pretty_print_name(assembly_template, include_namespace: true)
              "Component '#{cmp_tmpl_name}' is referenced by assembly template '#{assembly_template_name}'"
            end
          end
        end
      end
    end
  end
end