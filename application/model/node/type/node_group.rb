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
module DTK; class Node
  class Type
    class NodeGroup < self
      Types =
          [
           :stub,     # - in an assembly template
           :instance, # - in a service instance where actual nodes correspond to it
           :staged    # - in a service instance before actual nodes correspond to it
          ]
      def self.types
          @types ||= Types.map { |r| type_from_name(r) }
      end

      def self.model_name(type)
        case type.to_sym
        when :node_group_stub, :node_group_staged then :service_node_group
        when :node_group_instance then :node_group
        else fail Error.new("Unexpected node group type (#{type})")
        end
      end

      StagedTypes = [:staged]
      def self.is_staged?(type)
        StagedTypes.include?(type.to_sym)
      end

      private

      def self.type_from_name(type_name)
        "node_group_#{type_name}".to_sym
      end
      Types.each do |type_name|
        class_eval("def self.#{type_name}(); '#{type_from_name(type_name)}'; end")
      end
    end
  end
end; end