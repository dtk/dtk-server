module DTK; class AssemblyModule
  class Component
    class AdHocLink < self
      def initialize(assembly,parsed_adhoc_link)
        @assembly = assembly
        @source_attr_pattern = parsed_adhoc_link.attribute_pattern(:source)
        @target_attr_pattern = parsed_adhoc_link.attribute_pattern(:target)
      end

      def update_assembly_module(opts={})
      #determine which is the dependent component and which is the antec one 
        dep_cmp_template,antec_cmp_template = determine_dep_and_antec_components(opts)
        opts_craete_dep = {
          :antec_attr_pattern => @source_attr_pattern,
          :dep_attr_pattern => @target_attr_pattern
        }
        Dependency.create_dependency?(:link,@assembly,dep_cmp_template,antec_cmp_template,opts_craete_dep)
      end

     private
      def determine_dep_and_antec_components(opts={})
        unless target_cmp = @target_attr_pattern.component_instance()
          raise Error.new("Unexpected that target_attr_pattern.component() is nil")
        end
        #source_cmp can be nil when link to a node attribute
        source_cmp = @source_attr_pattern.component_instance()
        unless source_cmp
          raise Error.new("Not implemented yet when source_cmp is nil")
        end
        #TODO: stub heuristic that chooses target_cmp as dependency
        dep_cmp_template = target_cmp.get_component_template_parent()
        antec_cmp_template = source_cmp.get_component_template_parent()
        [dep_cmp_template,antec_cmp_template]
      end
    end
  end
end;end
