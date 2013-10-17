module DTK; class AssemblyModule
  class Component
    class Dependency < self
      def self.create_dependency?(assembly,cmp_template,antecedent_cmp_template,opts={})
        component_module = cmp_template.get_component_module()
        module_and_branch_info = create_assembly_branch?(assembly,component_module)
        module_branch = module_and_branch_info[:module_branch_idh].create_object()

        branch_cmp_template = get_branch_template(module_branch,cmp_template)
        branch_antec_cmp_template = get_branch_template(module_branch,antecedent_cmp_template)

        create(assembly,branch_cmp_template,branch_antec_cmp_template,opts).create_dependency?(opts)
      end

     private
      def self.get_branch_template(module_branch,cmp_template)
        #TODO: stub
        cmp_template
      end
      def self.create(assembly,branch_cmp_template,branch_antec_cmp_template,opts={})
        klass(assembly,branch_cmp_template,branch_antec_cmp_template,opts).new(assembly,branch_cmp_template,branch_antec_cmp_template)
      end

      def initialize(assembly,branch_cmp_template,branch_antec_cmp_template)
        @assembly = assembly
        @branch_cmp_template = branch_cmp_template
        @branch_antec_cmp_template = branch_cmp_template
      end

      def self.klass(assembly,cmp_template,antecedent_cmp_template,opts={})
        Simple #TODO: stub
      end

      class Simple < self
        def create_dependency?(opts={})
          if dependency_exists?()
          end
        end
       private
        def dependency_exists?()
          existing_deps = @branch_cmp_template.get_dependencies_simple()
          pp [:existing_deps,existing_deps]
          nil
        end
      end

      class Link < self
      end
    end
  end
end; end
