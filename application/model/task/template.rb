module DTK; class Task
  class Template < Model
    class ConfigComponents < self
      def self.generate(assembly,component_type=nil)
        ret = create_stub(assembly.model_handle(:task_template))
        cmp_list = ComponentList.get(assembly,component_type)
        pp [:cmp_list,cmp_list]
        ret
      end
      class ComponentList < Array
        def self.get(assembly,component_type=nil)
          opts = Hash.new
          if (component_type == :smoketest)
            opts.merge!(:filter_proc => lambda{|el|el[:basic_type] == "smoketest"}) 
          end
          assembly_cmps = assembly.get_component_list(:seed => ComponentList.new())
          node_centric_cmps = NodeGroup.get_component_list(assembly_cmps.map{|r|r[:node]},:seed => ComponentList.new())
          node_centric_cmps + assembly_cmps
        end
      end
    end
  end
end; end
