module DTK; class Component
  class Instance
    class Dependency #This represents both internode and intranode dependencies; anything that shows up in the depends_on section of the dsl
      def self.get_indexed(id_handles)
        ndx_with_deps = Component.get_component_type_and_dependencies(id_handles)
        #TODO: alos include link defs ones
        ndx_with_deps.inject(Hash.new){|h,(k,v)|h.merge(k => v[:component_dependencies]||[])}
      end
    end
  end
end; end
