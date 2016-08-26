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
  module CommonDSL::Generate
    class ContentInput
      class Assembly < ContentInput::Hash
        require_relative('assembly/diff')

        require_relative('assembly/attribute')
        # attribute must be before node and component
        require_relative('assembly/node')
        require_relative('assembly/component')

        def self.generate_content_input(assembly_instance)
          new.generate_content_input!(assembly_instance)
        end
        
        def generate_content_input!(assembly_instance)
          set_id_handle(assembly_instance)
          nodes = ContentInput::Hash.new
          components = ContentInput::Hash.new
          Node.generate_content_input(assembly_instance).each do | key, content_input_node |
            if content_input_node[:is_assembly_wide_node]
              components.merge!(content_input_node.val(:Components) || {})
            else
              nodes.merge!(key => content_input_node)
            end
          end

          # TODO: add assembly level attributes
          set(:Nodes, nodes) unless nodes.empty?
          set(:Components, components) unless components.empty?
          # TODO: add assembly level workflows

          self
        end

         ### For diffs
        def diff?(assembly_parse, key = nil)
          aggregate_diffs?(key) do |diff_set|
            diff_set.add? Node.diff_set(val(:Nodes), assembly_parse.val(:Nodes))
            diff_set.add? Component.diff_set(val(:Components), assembly_parse.val(:Components))
            # TODO: need to add diffs on all subobjects
            # ...
          end
        end

      end
    end
  end
end
