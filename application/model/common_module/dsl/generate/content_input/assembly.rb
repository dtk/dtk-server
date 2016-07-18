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
  module CommonModule::DSL::Generate
    class ContentInput
      class Assembly < ContentInput::Hash
        require_relative('assembly/node')
        require_relative('assembly/component')
        require_relative('assembly/attribute')

        def self.generate_content_input(assembly_instance)
          new.generate_content_input!(assembly_instance)
        end
        
        def generate_content_input!(assembly_instance)
          nodes = ContentInput::Array.new
          components = ContentInput::Array.new
          Node.generate_content_input(assembly_instance).each do | content_input_hash |
            if content_input_hash[:is_assembly_wide_node]
              components += (content_input_hash.val(:components) || ContentInput::Array.new)
            else
              nodes << content_input_hash
            end
          end
          set(:Nodes, nodes) unless nodes.empty?
          set(:Components, components) unless components.empty?
          # TODO: add assembly level attributes, workflows, ...
          pp [:debug, self]
          
          # TODO: stub: blob not interpreted and straight dump of info
          # need to use variation of cut and paste info and to break into sub objects that have canonical keys
          merge!(assembly_instance.info)
          self
        end
      end
    end
  end
end
=begin
{:name=>"simple",
     :description=>"Simple assembly for DTK-2554",
     :attributes=>[{:name=>"global_num", :value=>5}],
     :nodes=>
      [{:name=>"n1",
        :attributes=>
         [{:name=>"image", :value=>"amazon_hvm"},
          {:name=>"size", :value=>"small"}],
        "components"=>
         [{"host::hostname"=>{"attributes"=>{"hostname"=>"host1"}}}]}],
     "workflows"=>
      {"create"=>
        {"subtasks"=>
          [{"name"=>"set hostname", "components"=>["host::hostname"]}]}}}]}]
=end
