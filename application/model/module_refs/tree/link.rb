module DTK; class ModuleRefs
  class Tree
    class Link
      attr_reader :module_ref
      def initialize(module_ref)
        @module_ref = module_ref
        @components = Array.new
        @tree = nil
      end
      def self.match_component_module?(links,cmp_module)
        ret = nil
        matching_links = links.select{|l|l.match_component_module?(cmp_module)}
        unless matching_links.size == 1
          Log.error("Unexpected that not single to component module #{cmp_module.inspect}; match is: #{matching_links.inspect}")
          return ret
        end
        matching_links.first
      end
      def match_component_module?(cmp_module)
        @module_ref[:module_name] == cmp_module[:display_name]
      end

      def add_children!(component_module_refs)
        component_module_refs.component_modules.each do |cmr|
          pp cmr
        end
      end

    end
  end
end; end
