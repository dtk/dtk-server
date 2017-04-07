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
  module NodeComponent
    class IAAS
      TYPES = [:ec2]
      TYPES.each { |iaas_type| require_relative("iaas/#{iaas_type}") }

      attr_reader :component, :node_name
      def initialize(node_name, component_with_attributes)
        @node_name      = node_name
        @component      = component_with_attributes.component
        # @ndx_attributes is indexed by attribute name
        @ndx_attributes = component_with_attributes.attributes.inject({}) { |h, attr| h.merge!(attr.display_name => attr) } 
      end

      def self.create(iaas_type, node_name, component_with_attributes)
        klass(iaas_type).new(node_name, component_with_attributes)
      end

      private

      def self.klass(iaas_type)
        fail Error, "Illegal iaas_type '#{iaas_type}'" unless TYPES.include?(iaas_type)
        const_get iaas_type.to_s.capitalize 
      end

    end
  end
end
