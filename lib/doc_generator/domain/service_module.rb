module DTK; class DocGenerator; class Domain
  class ServiceModule < self
    r8_nested_require('service_module', 'input')
    
    def self.normalize_top(parsed_dsl__service_module)
      input = Input.create(parsed_dsl__service_module)
      { :module => normalize(input) }
    end

    def initialize(input)
      base(input)
      @assemblies = input.array__combine_assembly_info { |assembly| Assembly.normalize(assembly) }
      @component_module_refs = input.array(:component_module_refs).map { |cmr| ModuleRef::Component.normalize(cmr) }
      @component_module_refs.sort! { |a,b| ModuleRef::Component.compare(a,b) }
    end

    class Assembly < self
      def initialize(input)
        raw_input_assembly = input.hash(:raw).hash(:assembly)
        base(input)
        @actions = input.array(:task_template).map { |action| Action.normalize(action) }
        @components = raw_input_assembly.array(:components).map { |component| Component.normalize(raw_input(component)) }
        @nodes = raw_input_assembly.array(:nodes).map do |node| 
          unless node.scalar(:display_name) == 'assembly_wide'
            Node.normalize(raw_input(node)) 
          end
        end.compact
      end
    end

    class Node < self
      def initialize(input)
        raw_input = input.hash(:raw)
        base(raw_input)
        @components = raw_input.array(:components).map { |component| Component.normalize(raw_input(component)) }
      end
    end

    class Component < self
      def initialize(input)
        raw_input = input.hash_or_scalar(:raw)
        @name = name(raw_input)
      end
      private
       def name(raw_input)
         raw_input.kind_of?(Hash) ? raw_input.keys.first : raw_input
       end
     end

    class Action < self
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




