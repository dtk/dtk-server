module DTK; class Task; class Template
  class ActionList
    class ConfigComponents < self
      def self.get(assembly,opts={})
        opts_assembly_cmps = {:seed => new()}
        if cmp_type_filter = opts[:component_type_filter]
          opts_assembly_cmps.merge!(:filter_proc => lambda{|el|(el[:nested_component]||{})[:basic_type] == cmp_type_filter.to_s}) 
        end
        assembly_cmps = assembly.get_component_list(opts_assembly_cmps)
        #TODO: may treat filter on NodeGroup.get_component_list
        ret = NodeGroup.get_component_list(assembly_cmps.nodes(),:add_on_to => assembly_cmps)
        ret.set_action_indexes!()
      end
    end

    def nodes()
      ndx_ret = Hash.new
      each do |r|
        node = r[:node]
        ndx_ret[node[:id]] ||= node
      end
      ndx_ret.values()
    end
  end
end; end; end


