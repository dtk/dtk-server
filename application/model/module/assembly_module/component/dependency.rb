module DTK; class AssemblyModule
  class Component
    class Dependency < self
      def self.create_dependency?(type,assembly,cmp_template,antecedent_cmp_template,opts={})
        component_module = cmp_template.get_component_module()
        module_and_branch_info = create_assembly_branch?(assembly,component_module)
        module_branch = module_and_branch_info[:module_branch_idh].create_object()
        unless branch_cmp_template = get_branch_template(module_branch,cmp_template)
          raise Error.new("Unexpected that branch_cmp_template is nil")
        end
        dependency_class(type).create_dependency?(branch_cmp_template,antecedent_cmp_template,opts)
      end

     private
      def self.get_branch_template(module_branch,cmp_template)
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:component_type],
          :filter => [:and,[:eq,:module_branch_id,module_branch.id()],
                      [:eq,:type,'template'],
                      [:eq,:component_type,cmp_template.get_field?(:component_type)]]
        }
        Model.get_obj(cmp_template.model_handle(),sp_hash)
      end

      def self.dependency_class(type)
        case type 
          when :simple then DTK::Dependency::Simple 
          when :link then DTK::Dependency::Link
        else
          raise Error.new("Illegal type")
        end
      end
    end
  end
end; end
