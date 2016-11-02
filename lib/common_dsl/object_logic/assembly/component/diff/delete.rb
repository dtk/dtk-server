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
      class Delete < CommonDSL::Diff::Element::Delete
        require_relative('delete/task_template')

        include Mixin

        # opts can have keys:
        #   :force_delete - delete without adding delete actions
        def process(result, opts = {})
          augmented_cmps = assembly_instance.get_augmented_components(Opts.new(filter_component: component_name))
          if augmented_cmps.empty?
            result.add_error_msg("Component '#{qualified_key.print_form}' does not match any components")
          else
            node          = parent_node? || assembly_instance.has_assembly_wide_node?
            matching_cmps = augmented_cmps.select{|cmp| cmp[:node][:display_name] == node[:display_name]}

            if matching_cmps.size > 1
              result.add_error_msg("Unexpected that component name '#{qualified_key.print_form}' match multiple components")
            else
              component = DTK::Component::Instance.create_from_component(matching_cmps.first)
              TaskTemplate.insert_explict_delete_action?(assembly_instance, component, node, force_delete: opts[:force_delete])
              # assembly_instance.delete_component can update task template by removing step that has componentt 
              # TODO: DTK-2680: Rich: I don't think we should call below when there is .delete action on component because
              # we don't want to delete component from the database, just want to remove it from config node workflow
              # we should probably just call somethig like - template_content.delete_explicit_action?(@new_action, @action_list) to delete
              # create component action from workflow
              # assembly_instance.delete_component(component.id_handle, node.id)

              result.add_item_to_update(:assembly)
              result.add_item_to_update(:workflow)
            end
          end
        end

      end
    end
  end
end; end
