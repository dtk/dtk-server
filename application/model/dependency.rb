module DTK
  class Dependency < Model
    # because initially Dependency only refered to simple dependencies; introduced Simple and Links and their parent All
    # TODO: may have what is attached to Model be Dependency::Simple and have Dependency become what is now All  

    class All; end
    r8_nested_require('dependency','simple')
    r8_nested_require('dependency','link')
    class All 
      def initialize()
        @satisfied_by_component_ids = []
      end

      attr_reader :satisfied_by_component_ids

      def self.augment_component_instances!(assembly,components,opts=Opts.new)
        return components if components.empty?
        Dependency::Simple.augment_component_instances!(components,opts)
        Dependency::Link.augment_component_instances!(assembly,components,opts)
        components
      end
    end

    # if this has simple filter, meaning test on same node as dependency then return it, normalizing to convert strings into symbols
    def simple_filter_triplet?()
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

    # if its simple component type match returns component type
    def is_simple_filter_component_type?()
      if filter_triplet = simple_filter_triplet?()
        SimpleFilter.create(filter_triplet).component_type?()
      end
    end

    def component_satisfies_dependency?(cmp)
      if filter_triplet = simple_filter_triplet?()
        SimpleFilter.create(filter_triplet).match?(cmp)
      end
    end

    class SimpleFilter
      def self.create(triplet)
        const_get(triplet[0].to_s.capitalize()).new(triplet)
      end

      def component_type?()
      end

     private
      def initialize(triplet)
        @field = triplet[1]
        @value = triplet[2]
      end

      class Eq < self
        def match?(component)
          component.has_key?(@field) and @value == component[@field]
        end
        
        def component_type?()
          @value if @field == :component_type
        end
      end
    end

  end
end


