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
  class Component
    # For components with special semantics
    class Domain
      require_relative('domain/node')
      require_relative('domain/provider')

      def initialize(component)
        @component = component
      end

      def self.is_type_of?(component)
        legal_types.include?(component.get_field?(:component_type))
      end

      private

      attr_reader :component

      def attributes
        # @component[:attributes] is in case augmented component with attributes
        @attributes ||= @component[:attributes] || @component.get_attributes
      end


      def self.legal_types
        if const_defined?(:TYPES)
          self::TYPES
        else
          fail "Method should not be called on class '#{self}' because static type constant 'TYPES' not defined"
        end
      end

      def self.convert_to_component_display_name_form(internal_type_form)
        internal_type_form.gsub(/__/, '::')
      end

      def attribute_value?(attr_name)
        attr_name = attr_name.to_s
        if attr = attributes.find { |attr| attr_name == attr[:display_name] }
          attr[:attribute_value]
        end 
      end

    end
  end
end

=begin
# TODO: may put back in
    require_relative('domain/nic')

    def initialize(component)
      # component with attributes
      @component      = component
      @component_type = self.class.component_type(component)
    end

    def self.on_node?(node)
      if filter = component_filter?
        # if there is a component filter then no need to do the is_a? check
        node.get_components(filter: filter, with_attributes: true).map { |component| create(component) }
      else
        node.get_components(with_attributes: true).map { |component| create(component) if is_a?(component) }.compact
      end
    end

    private
    
    # TODO: might want to find more robust way to determine which components are nics
    def self.is_a?(component)
      component_types.include?(component_type(component))
    end

    def self.component_type(component)
      component.get_field?(:component_type)
    end

    def self.create(component)
      new(component)
    end

    def self.component_filter?
      [:oneof, :component_type, component_types]
    end

  end
end; end
=end
