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
    class IAAS < self
      require_relative('iaas/mixin')
      require_relative('iaas/host_attributes')

      TYPES = [:ec2]
      TYPES.each { |iaas_type| require_relative("iaas/#{iaas_type}") }

      def self.create(assembly, node, component_with_attributes)
        iaas_type = iaas_type(component_with_attributes.component)
        klass(iaas_type, node).new(assembly, node, component_with_attributes)
      end

      def update_attribute!(attribute_name, attribute_value)
        attribute = attribute(attribute_name)
        attribute[:value_asserted] = attribute_value
        attribute[:value_derived]  = nil
        Attribute.update_and_propagate_attributes(attribute_model_handle, [attribute], add_state_changes: false, partial_value: false)
      end

      private      
      def self.klass(iaas_type, node)
        klass_base(iaas_type).const_get('Type').const_get(node.is_node_group?  ? 'Group' : 'Instance')
      end

      def self.klass_base(iaas_type)
        fail Error, "Illegal iaas_type '#{iaas_type}'" unless TYPES.include?(iaas_type)
        const_get(iaas_type.to_s.capitalize)
      end

    end
  end
end
