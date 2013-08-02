module DTK; class Task
  class Template < Model
    class ConfigComponents < self
      def self.get_components(assembly,component_type=nil)
        opts = Hash.new
        if (component_type == :smoketest)
          opts.merge!(:filter_proc => lambda{|el|el[:basic_type] == "smoketest"}) 
        end
        assembly_cmps = assembly.get_component_list()
        node_centric_cmps = NodeGroup.get_component_list(assembly_cmps.map{|r|r[:node]})
        node_centric_cmps + assembly_cmps
      end
    end
  end
end; end
