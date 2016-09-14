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
        def process(result, opts = {})
          matching_aug_cmp_templates = ::DTK::Component::Template.find_matching_component_templates(assembly_instance, component_name) 
          aug_cmp_template = nil

          if matching_aug_cmp_templates.empty?
            result.add_error_msg("Component '#{qualified_key.print_form}' does not match any installed component templates")
          elsif matching_aug_cmp_templates.size > 1
            # TODO: put in message the name of matching component templates
            aug_cmp_template = find_matching_dependency(matching_aug_cmp_templates, opts[:dependent_modules])

            unless aug_cmp_template
              error_msg = "Component '#{qualified_key.print_form}' matches multiple installed component templates. Please select one of the following templates by adding under dependencies key inside 'dtk.service.yaml' file:"
              error_msg += "\n#{pretty_print_templates(matching_aug_cmp_templates).join(",\n")}"
              result.add_error_msg(error_msg)
            end
          else
            aug_cmp_template = matching_aug_cmp_templates.first
          end

          if aug_cmp_template
            # TODO: use this and node to add component to node
            # node is gotten by looking at qualified_key
            # case on whether assembly or node level
          end
        end

        private

        def component_name
          relative_distinguished_name
        end

        def find_matching_dependency(matching_aug_cmp_templates, dependencies = {})
          return if dependencies.empty?

          ret = nil
          dependencies.each do |name, version|
            ret = match_templates_against_dependency(matching_aug_cmp_templates, name, version)
            break if ret
          end

          ret
        end

        def match_templates_against_dependency(templates, dep_name, dep_version = 'master')
          templates.find{ |template| "#{template[:namespace][:display_name]}/#{template[:display_name]}".eql?(dep_name) && template[:version].eql?(dep_version) }
        end

        def pretty_print_templates(templates)
          temp_array = []

          templates.each do |template|
            temp_array << "#{template[:namespace][:display_name]}/#{template[:display_name]}: #{template[:version]}"
          end

          temp_array
        end

      end
    end
  end
end; end
