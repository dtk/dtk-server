module DTK; class Component
  # For special objects               
  class Domain
    r8_nested_require('domain', 'nic')

    def initialize(component)
      @component = component
    end

    def self.on_node?(node)
      if component_filter = component_filter?
        node.get_components(component_filter?).map { |component| new(component) }
      else
        node.get_components().map { |component| is_a?(component) }.compact
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
    def component_filter?
      nil
    end

  end
end; end
