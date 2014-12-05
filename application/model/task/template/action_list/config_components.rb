module DTK; class Task; class Template
  class ActionList
    class ConfigComponents < self
      def self.get(assembly,opts={})
        # component_list_filter_proc includes clause to make sure no target refs
        opts_assembly_cmps = {:seed => new(),:filter_proc => component_list_filter_proc(opts)}
        assembly_cmps = assembly.get_component_list(opts_assembly_cmps)
        # NodeGroup.get_component_list looks for any components in inventory node groups
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

   private
    def self.component_list_filter_proc(opts={})
      if cmp_type_filter = opts[:component_type_filter]
        lambda{|el|(el[:node].nil? or !el[:node].is_target_ref?) and (el[:nested_component]||{})[:basic_type] == cmp_type_filter.to_s}
      else
        lambda{|el|el[:node].nil? or !el[:node].is_target_ref?}
      end
    end
  end
end; end; end


