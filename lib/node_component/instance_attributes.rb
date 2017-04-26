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
  class NodeComponent
    class InstanceAttributes < ::Hash
      def initialize(node, attributes_name_value_hash)
        super()
        name_value_hash = iaas_normalize(attributes_name_value_hash)
        replace(name_value_hash.inject(display_name_hash(node)) { |h, (n, v)| h.merge(n.to_sym => v) })
        @node = node
      end
      attr_reader :node

      def value?(name)
        self[name.to_sym]
      end

      private

      def iaas_normalize(attributes_name_value_hash)
        fail Error::NoMethodForConcreteClass.new(self.class)
      end

      def display_name_hash(node, opts = {})
        { display_name: node.assembly_node_print_form }
      end
      
    end
  end
end

