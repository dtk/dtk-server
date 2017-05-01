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

module DTK
  class Component
    module Name
      # For component instances
      module Instance
        module ClassMixin
          # context can have keys
          #  :assembly_id
          #  :allow_external_component (Boolean)
          def check_valid_id(model_handle, id, context = {})
            filter = Name::Instance.add_assembly_id_clause?([:eq, :id, id], context)
            check_valid_id_helper(model_handle, id, filter)
          end
          
          # The possible forms for name are
          #   node/component_name
          #   node/module_name::component_name
          #   component_name
          #   module_name::component_name
          # along with above variants with [title] is at end
          # the later two are for assemble wide components
          #
          # context can have keys
          #  :assembly_id
          #  :allow_external_component (Boolean)
          def name_to_id(model_handle, name, context = {})
            if context.empty?
              return name_to_id_default(model_handle, name)
            end
            name_to_object(model_handle, name, context).id
          end
          
          def name_to_object(model_handle, name, context = {})
            assembly_id              = context[:assembly_id]
            allow_external_component = context[:allow_external_component]
            
            display_name = Component.display_name_from_user_friendly_name(name)
            # setting node_prefix to true, but node_name can be nil, meaning an assembly-wide component instance
          node_name, cmp_type, cmp_title = ComponentTitle.parse_component_display_name(display_name, node_prefix: true)
            
            sp_hash = {
              cols:   [:id, :node, :assembly_id],
              filter: Name::Instance.add_assembly_id_clause?(Component::Instance.filter(cmp_type, cmp_title), context)
            }
            
            rows = get_objs(model_handle, sp_hash).select do |r|
              r[:node][:display_name] == node_name or r[:node].is_assembly_wide_node?
            end
            
            if context[:filter_by_node] && node_name
              rows.reject!{|cmp| cmp[:node][:display_name] != node_name}
            end
            
            case rows.size
            when 1
              rows.first
            when 0
              fail ErrorNameDoesNotExist.new(name, pp_object_type())
            else # rows.size > 1
              # if allow_external_component, favor a component instance in the service instance 
              if allow_external_component and assembly_id
                internal_to_assembly = rows.select { |r| r[:assembly_id] == assembly_id }
                if internal_to_assembly.size == 1
                  return internal_to_assembly.first
                end
              end
              fail ErrorNameAmbiguous.new(name, rows.map { |r| r[:id] }, pp_object_type())
            end
          end
        end
        
        # internal methods
        # context can have keys
        #  :assembly_id
        #  :allow_external_component (Boolean)
        def self.add_assembly_id_clause?(base_filter, context = {})
          ret = base_filter
          if assembly_id = context[:assembly_id]
            unless context[:allow_external_component ]
              ret = [:and, ret, [:eq, :assembly_id, assembly_id]]
            end
          end
          ret
        end
        
      end
    end
  end
end
