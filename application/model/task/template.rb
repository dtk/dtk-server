module DTK; class Task
  class Template < Model
    class ConfigComponents < self
      def self.get_components(assembly,component_type=nil)
        opts = Hash.new
        if (component_type == :smoketest)
          opts.merge!(:filter_proc => lambda{|el|el[:basic_type] == "smoketest"}) 
        end
        assembly.get_component_list()
      end
    end
  end
end; end
