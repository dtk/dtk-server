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
module DTK; class Attribute
  class Pattern
    class Node < self
      def self.create(pattern, node, _opts = {})
        if pattern =~ /^[0-9]+$/
          return Type::ExplicitId.new(pattern, node)
        end
        split_term = pattern.split('/')
        node_name = node.get_field?(:display_name)
        case split_term.size
          when 1
            Type::NodeLevel.new("node[#{node_name}]/attribute[#{split_term[0]}]")
          when 2
            Type::ComponentLevel.new("node[#{node_name}]/component[#{split_term[0]}]/attribute[#{split_term[1]}]")
          else
            fail ErrorUsage::Parsing::Term.new(pattern, :node_attribute)
        end
      end
    end
  end
end; end