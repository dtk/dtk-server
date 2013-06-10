module DTK
  class Dependency < Model
    r8_nested_require('dependency','simple')
    r8_nested_require('dependency','derived')

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

    def self.find_in_depends_on_form(components)
      raise Error.new("write this in terms of def Dependency#depends_on_form")
    end
  end
end


