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
  class ServiceSetting
    class NodeBindings < Array
      def initialize(content)
        super()
        self.class.each_element(content) { |el| self << el }
      end

      def set_node_bindings(target, assembly)
        hash_content = inject({}) { |h, el| h.merge(el.hash_form) }
        ::DTK::NodeBindings::DSL.set_node_bindings(target, assembly, hash_content)
      end

      private

      def self.each_element(content, &block)
        content.each_pair do |assembly_node, node_target|
          block.call(Element.new(assembly_node, node_target))
        end
      end

      class Element
        attr_reader :assembly_node
        def initialize(assembly_node, node_target)
          @assembly_node = assembly_node
          @node_target = node_target
        end

        def hash_form
          { @assembly_node => @node_target }
        end
      end
    end
  end
end