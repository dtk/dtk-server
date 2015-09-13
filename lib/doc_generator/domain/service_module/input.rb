module DTK; class DocGenerator; class Domain
  class ServiceModule
    class Input < Domain::Input
      def self.create(dsl)
        input_hash = {
          display_name:          dsl.display_name,  
          component_module_refs: dsl.component_module_refs, 
          assembly_workflows:    dsl.assembly_workflows, 
          raw:                   dsl.assembly_raw_hashes
        }
        new(input_hash)
      end

      def array__combine_assembly_info(&block)
        ret = []
        ndx_assemblies = array(:assembly_workflows).inject({}) { |h,i| h.merge(i.scalar(:display_name) => i) }
        (self[:raw] || {}).each_pair do |assembly_name, assembly_raw_hash|
          (ndx_assemblies[assembly_name] ||= Input.new).merge!(Input.raw_input(assembly_raw_hash))
        end
        ndx_assemblies.values.each { |assembly| ret << block.call(assembly)}
        ret
      end
    end
  end
end; end; end
