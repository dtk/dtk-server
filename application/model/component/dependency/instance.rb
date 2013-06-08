module DTK; class Component
  class Dependency
    class Instance < self 
      def self.get_indexed(cmp_instance_idhs,opts=Opts.new)
        ret = Array.new
        return ret if cmp_instance_idhs.empty?
        sample_idh = cmp_instance_idhs.first
        sp_hash = {
          :cols => [:id,:inherited_dependencies, :extended_base, :component_type],
          :filter => [:oneof, :id, cmp_instance_idhs.map{|idh|idh.get_id()}]
        }
        cmp_mh = cmp_instance_idhs.first.createMH()
        components = Model.get_objs(cmp_mh,sp_hash)
        simple_deps = find_component_simple_dependencies(components)
        if opts[:return] == :component_type_and_simple_dependencies
          return simple_deps
        end

        #TODO: also include link defs ones
        simple_deps.inject(Hash.new){|h,(k,v)|h.merge(k => v[:component_dependencies]||[])}
      end
     private

      #assumption that this is called with components having keys :id,:dependencies, :extended_base, :component_type 
      def self.find_component_simple_dependencies(components)
        ret = Hash.new
        cmp_idhs = Array.new
        components.each do |cmp|
          unless pntr = ret[cmp[:id]]
            pntr = ret[cmp[:id]] = {:component_type => cmp[:component_type], :component_dependencies => Array.new}
            cmp_idhs << cmp.id_handle()
          end
          if cmp[:extended_base]
            pntr[:component_dependencies] << cmp[:extended_base]
          elsif deps = cmp[:dependencies]
            #process dependencies
            #TODO: hack until we have macros which will stamp the dependency to make this easier to detect
            #looking for signature where dependency has
            #:search_pattern=>{:filter=>[:and, [:eq, :component_type, <component_type>]
            filter = (deps[:search_pattern]||{})[":filter".to_sym]
            if filter and deps[:type] == "component"
              if filter[0] == ":eq" and filter[1] == ":component_type"
                pntr[:component_dependencies] << filter[2]
              end
            end
          end
        end
        ComponentOrder.update_with_applicable_dependencies!(ret,cmp_idhs)
      end

    end
  end
end; end
