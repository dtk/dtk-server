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
  class Assembly::Instance
    module Add
      # for adding components
      module Component
        module Mixin
          # aug_cmp_template is a component template augmented with keys having objects
          # :module_branch
          # :component_module
          # :namespace
          # opts can have keys
          #  :update_workflow
          #  :auto_complete_links
          #  :component_title
          # TODO: are these two below still used (i..e, set from calling function)
          #  :skip_if_not_found
          #  :splice_in_delete_action
          def add_component(node_idh, aug_cmp_template, opts = {})
            node = Component.check_node(self, node_idh)
            component = nil          
            Transaction do
              # add the component
              component = node.add_component(aug_cmp_template, component_title: opts[:component_title], detail_to_include: [:component_dependencies]).create_object
              if opts[:update_workflow]
                Component.update_workflow(self, node, component, Aux.hash_subset(opts, [:skip_if_not_found, :splice_in_delete_action]))
              end
              
              if opts[:auto_complete_links]
                LinkDef::AutoComplete.autocomplete_component_links(self, components: [component])
              end
            end
            component.id_handle 
          end
        end

        def self.check_node(assembly_instance, node_idh)
          # first check that node_idh is directly attached to the assembly instance
          # one reason it may not be is if its a node group member
          sp_hash = {
            cols: [:id, :display_name, :group_id, :ordered_component_ids],
            filter: [:and, [:eq, :id, node_idh.get_id], [:eq, :assembly_id, assembly_instance.id]]
          }

          unless node = Model.get_obj(assembly_instance.model_handle(:node), sp_hash)
            if node_group = assembly_instance.is_node_group_member?(node_idh)
              fail ErrorUsage, "Not implemented: adding a component to a node group member; a component can only be added to the node group (#{node_group[:display_name]}) itself"
            else
              fail ErrorIdInvalid.new(node_idh.get_id, :node)
            end
          end
          node
        end
        
        # opts can have keys
        #  :component_title
        #  :skip_if_not_found
        #  :splice_in_delete_action
        def self.update_workflow(action_instance, node, component, opts = {})
          update_opts = { skip_if_not_found: true }
          if opts[:splice_in_delete_action]
            cmp_instance = ::DTK::Component::Instance.create_from_component(component)
            action_def = cmp_instance.get_action_def?('delete')
            update_opts.merge!(:action_def => action_def)
          end
          if component_title = opts[:omponent_title]
            update_opts.merge!(:component_title => component_title)
          end
          Task::Template::ConfigComponents.update_when_added_component_or_action?(action_instance, node, component, update_opts)
        end

      end
    end
  end
end
