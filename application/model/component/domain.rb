module DTK; class Component
  # For special objects               
  class Domain
    r8_nested_require('domain', 'nic')

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

    def match_attribute_value?(attr_name)
      attr_name = attr_name.to_s
      if attr = attributes.find { |attr| attr_name == attr[:display_name] }
        attr[:attribute_value]
      end 
    end

    def attributes
      @component[:attributes] || []
    end
  end
end; end
