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
  module CommonDSL
    module ObjectLogic
      class Dependency < Generate::ContentInput::Hash
        def self.generate_content_input(assembly_instance, module_branch)
          new.generate_content_input!(assembly_instance, module_branch)
        end

        def generate_content_input!(assembly_instance, module_branch)
          set_id_handle(assembly_instance)

          components = ObjectLogic.new_content_input_hash
          dependencies = ObjectLogic.new_content_input_hash

          Assembly::Node.generate_content_input(assembly_instance).each do | key, content_input_node |
            components = content_input_node.val(:Components)
          end

          unless components.empty?
            module_refs = module_branch.get_module_refs
            components.each do |name, _component|
              match = module_refs.select{ |mr| mr[:display_name].eql?(name) }
              if match.empty?
                # TODO: should return error that no matches found
                next
              elsif match.size == 1
                mr_match = match.first
                dependencies.merge!({ "#{mr_match[:namespace_info]}/#{mr_match[:display_name]}" => (mr_match[:version_info] || 'master') })
              else
                # TODO: should return error that multiple matches are found
                next
              end
            end
          end

          dependencies
        end

      end
    end
  end
end
