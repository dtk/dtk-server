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
        include Mixin

        def process(result, opts = {})
          # TODO: DTK-2665: look at whether should instead use Diff::DiffErrors.raise_error, rather than result.add_error_msg 
          # and whether should trap errors, e.g., when call assembly_instance.add_component so can augment error message with
          # diff change reference (i.e, qualified_key, change_type=component and operation=add)
          matching_aug_cmp_templates = ::DTK::Component::Template.find_matching_component_templates(assembly_instance, component_name) 
          aug_cmp_template = nil

          if matching_aug_cmp_templates.empty?
            result.add_error_msg("Component '#{qualified_key.print_form}' does not match any installed component templates")
          elsif matching_aug_cmp_templates.size > 1
            # TODO: DTK-2665:  put in message the name of matching component templates
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
            # TODO: DTK-2650:  use this and node to add component to node
            # node is gotten by looking at qualified_key
            # case on whether assembly or node level
            if node = parent_node?
              add_component_to_node(node, aug_cmp_template, component_title: component_title?)
              result.add_item_to_update(:workflow) # workflow will be updated with spliced in new component
            else
              # TODO: DTK-2650:  need to call method that adds the component to top level assembly
            end
            raise 'got here' # TODO: DTK-2650: This will undo transactions so can retest a change to dtk.service.yaml that adds a component
            # TODO: DTK-2650: if comment this out and do push twiced second time wil not see a component added change, but wil see a diff in workflows unti            # logic is put in lib/common_dsl/diff.rb as noted that updates the dsl from the object model and signals the client to pull the changes
            # a temporary thing to also consider is calling assembly_instance.add_component
            # as assembly_instance.add_component(node.id_handle, aug_cmp_template, opts[:component_title], :donot_update_workflow: true)
            
            # TODO: DTK-2650: Put in logic to see if any attributes are part of the component add and if so then process; a sketch of this: adding method
            # def add_component_attributes(result)
            # modeled after add_nested_components in node/add.rb
          end 
        end

        private

        # opts can have keys:
        #   :component_title
        def add_component_to_node(node, aug_cmp_template, opts = {})
          assembly_instance.add_component(node.id_handle, aug_cmp_template, opts[:component_title])
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
