module DTK; class Component
  class Instance < self
    r8_nested_require('instance','dependency')
    
    def self.print_form(component)
      component.get_field?(:display_name).gsub(/__/,"::")
    end

    def self.version_print_form(component)
      ModuleBranch.version_from_version_field(component.get_field?(:version))
    end

  end
end; end
