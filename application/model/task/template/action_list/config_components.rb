module DTK; class Task; class Template
  class ActionList
    class ConfigComponents < self
      def self.get(assembly,component_type=nil)
        opts = Hash.new
        if (component_type == :smoketest)
          opts.merge!(:filter_proc => lambda{|el|el[:basic_type] == "smoketest"}) 
        end
        assembly_cmps = assembly.get_component_list(:seed => new())
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


