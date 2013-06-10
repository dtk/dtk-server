module DTK
  class Dependency < Model
    #because initially Dependency only refered to simple dependencies; introduced Simple and Links and their parent All
    #TODO: may have what is attached to Model be Dependency::Simple and have Dependency become what is now All  
    class All < Hash
      def initialize(initial_val={})
        super()
        unless initial_val.empty?
          replace(initial_val)
        end
      end

      def self.augment_component_instances!(components)
        return components if components.empty?
        Dependency::Simple.augment_component_instances!(components)
        Dependency::Link.augment_component_instances!(components)
        components

      end
    end

    r8_nested_require('dependency','simple')
    r8_nested_require('dependency','link')

    #if its simple component type match returns component type
    def is_simple_component_type_match?()
      #TODO: hack until we have macros which will stamp the dependency to make this easier to detect
      #looking for signature where dependency has
      #:search_pattern=>{:filter=>[:and, [:eq, :component_type, <component_type>]
      if filter = (deps[:search_pattern]||{})[":filter".to_sym]
        if deps[:type] == "component" and filter[0] == ":eq" and filter[1] == ":component_type"
          filter[2]
        end
      end
    end

  end
end


