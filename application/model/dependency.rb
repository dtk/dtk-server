module DTK
  class Dependency < Model
    #because initially Dependency only refered to simple dependencies; introduced Simple and Links and their parent All
    #TODO: may have what is attached to Model be Dependency::Simple and have Dependency become what is now All  
    class All 
      def self.augment_component_instances!(components,opts=Opts.new)
        return components if components.empty?
        Dependency::Simple.augment_component_instances!(components,opts)
        Dependency::Link.augment_component_instances!(components,opts)
        components
      end
    end

    r8_nested_require('dependency','simple')
    r8_nested_require('dependency','link')

    #if this has simple filter, meaning test on same node as dependency then return it, normalizing to convert strings into symbols
    def simple_filter?()
      if filter = (self[:search_pattern]||{})[":filter".to_sym]
        if self[:type] == "component" and filter.size == 3 
          logical_rel_string = filter[0]
          field_string = filter[1]
          if SimpleFilterRelationsToS.include?(logical_rel_string) and field_string =~ /^:/
            [logical_rel_string.gsub(/^:/,'').to_sym,field_string.gsub(/^:/,'').to_sym,filter[2]]
          end
        end
      end
    end
    SimpleFilterRelations = [:eq]
    SimpleFilterRelationsToS = SimpleFilterRelations.map{|r|":#{r.to_s}"}

    #if its simple component type match returns component type
    def is_simple_component_type_match?()
      #TODO: hack until we have macros which will stamp the dependency to make this easier to detect
      #looking for signature where dependency has
      #:search_pattern=>[:eq, :component_type, <component_type>]
      if simple_filter = simple_filter?()
        if simple_filter[1] == :component_type
          simple_filter[2]
        end
      end
    end

  end
end


