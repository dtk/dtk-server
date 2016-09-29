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
        include Mixin

        ##
        ## valid 'opts' arguments are
        ##   :force_delete - delete without generating workflow
        ##
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
              if component_delete_action_exists?(node) && !opts[:force_delete]
                # TODO: DTK-2680: add code that generates component delete task and add it to converge task
              else
                assembly_instance.delete_component(matching_cmps.first.id_handle, node[:id])
              end

              result.add_item_to_update(:assembly)
              result.add_item_to_update(:workflow)
            end
          end
        end

        private

        def component_delete_action_exists?(node)
          action_list = Task::Template::ActionList::ConfigComponents.get(assembly_instance)
          delete_action = Task::Template::Content.parse_and_reify({ :node => node[:display_name], actions: ["#{component_name}.delete"] }, action_list, skip_if_not_found: true)
          !delete_action.empty?
        end
      end
    end
  end
end; end
