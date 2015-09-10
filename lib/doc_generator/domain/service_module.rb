module DTK; class DocGenerator; class Domain
  class ServiceModule < self
    def self.normalize_top(parsed_dsl__service_module)
      dsl = parsed_dsl__service_module # for succinctness

      input = Input.new(component_module_refs: dsl.component_module_refs, assembly_tasks: dsl.assembly_tasks, display_name: dsl.display_name)  
      { :module => normalize(input) }
    end

    def initialize(input)
      base(input)
      @assemblies = input.array(:assembly_tasks).map { |assembly| Assembly.normalize(assembly) }

      @component_module_refs = input.array(:component_module_refs).map { |cmr| ModuleRef::Component.normalize(cmr) }
      @component_module_refs.sort! { |a,b| ModuleRef::Component.compare(a,b) }
    end

    class Assembly < self
      def initialize(input)
        base(input)
        @workflows = input.array(:task_template).map { |workflow| Workflow.normalize(workflow) }
      end
    end

    class Workflow < self
      def initialize(input)
        @name = Task::Template.task_action_external_name(input.scalar(:task_action))
      end
    end

    module ModuleRef
    end
    class ModuleRef::Component < self
      def initialize(input)
        @module_name = input.scalar(:module_name)
        @namespace   = input.scalar(:namespace_info)
      end

      # a and b are hashes
      def self.compare(a,b) 
        ret = (a['namespace'] || '') <=> (b['namespace'] || '')
        if ret == 0
          (a['module_name'] || '') <=> (b['module_name'] || '')
        end
        ret
      end
    end
      
  end
end; end; end




