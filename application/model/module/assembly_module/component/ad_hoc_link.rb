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
        dep_cmp,antec_cmp = determine_dep_and_antec_components(opts)
        dep_cmp_template = dep_cmp.get_component_template_parent()
        antec_cmp_template = antec_cmp.get_component_template_parent()
        opts_create_dep = {
          :antec_attr_pattern => @source_attr_pattern,
          :dep_attr_pattern => @target_attr_pattern,
          :update_dsl => true
        }
        Model.Transaction do
          result = Dependency.create_dependency?(:link,@assembly,dep_cmp_template,antec_cmp_template,opts_create_dep)
          if link_def_info = result[:link_def_created]
            service_type = link_def_info[:type]
            assembly.add_service_link?(service_type,dep_cmp.id_handle(),antec_cmp.id_handle())
          end
        end
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
        #TODO: stub heuristic that chooses target_cmp as dependent
        dep_cmp = target_cmp
        antec_cmp = source_cmp
        [dep_cmp,antec_cmp]
      end
    end
  end
end;end
