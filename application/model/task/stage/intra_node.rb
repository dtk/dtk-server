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
module XYZ
  module Stage
    class IntraNode
       def self.generate_stages(component_dependencies, state_change_list)
         return [component_dependencies] if component_dependencies.size == 1

         stages = []
         prev_deps_count = component_dependencies.size
         until (stage = generate_stage(component_dependencies)).empty?
              # Checks for inter node dependency cycle and throws error if cycle present
              prev_deps_count = detect_internode_cycle(component_dependencies, prev_deps_count, state_change_list)
           stages << stage
        end
        # Additional check in case when generate_stage method returns empty hash in first iteration
        detect_internode_cycle(component_dependencies, prev_deps_count, state_change_list)

        # Amar TODO: save intranode stages
        stages
      end

       private

      def self.generate_stage(component_dependencies)
        stage = {}
        parents = component_dependencies.keys
        component_dependencies.map do |parent, children|
          # If there are no component dependencies, add to stage
          if children.empty?
            stage[parent] = children
            next
          end
          # if all parrents and current children have no shared elements
          # or in other words if dep comps are not present in any of the parents,
          # add to stage
          stage[parent] = children if (parents & children).empty?
        end
        stage.map { |k, _v| component_dependencies.delete(k) }
        stage
      end

      def self.detect_internode_cycle(component_dependencies, prev_deps_count, state_change_list)
          cur_deps_count = component_dependencies.size
          if prev_deps_count == cur_deps_count && prev_deps_count != 0
            # Gathering data for error's pretty print on CLI side
            cmp_ids = component_dependencies.keys
            node_id = state_change_list.first[:node][:id]
            node_name = state_change_list.first[:node][:display_name]
            cmp_dep_str = []
            state_change_list.each do |cmp|
              cmp_dep_str << "#{cmp[:component][:display_name]}(ID: #{cmp[:component][:id]})" if cmp_ids.include?(cmp[:component][:id])
            end
            error_msg = "Intra-node components cycle detected on node '#{node_name}' (ID: #{node_id}) for components: #{cmp_dep_str.join(', ')}"
            fail ErrorUsage.new(error_msg)
          end
          cur_deps_count
        end
    end
  end
end