module DTK; class Component
  # For special objects               
  class Domain
    r8_nested_require('domain', 'nic')

    def initialize(component)
      # component with attributes
      @component = component
    end

    def self.on_node?(node)
      if filter = component_filter?
        # if there is a component filter then no need to do the is_a? check
        node.get_components(filter: filter, with_attributes: true).map { |component| new(component) }
      else
        node.get_components(with_attributes: true).map { |component| is_a?(component) }.compact
      end
    end

    def self.is_a?(component)
      new(component).is_a?
    end

    # this method gets overwritten; returns the Domain subclass object if @component is of type associated with subclass
    def is_a?
      nil
    end

    private

    def self.type
      self.class.to_s.split('::').first.to_sym
    end

    # this method can be overwritten
    def self.component_filter?
      nil
    end

  end
end; end
