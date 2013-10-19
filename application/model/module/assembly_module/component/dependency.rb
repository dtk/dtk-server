module DTK; class AssemblyModule
  class Component
    class Dependency < self
      def self.create_dependency?(assembly,cmp_template,antecedent_cmp_template,opts={})
        component_module = cmp_template.get_component_module()
        module_and_branch_info = create_assembly_branch?(assembly,component_module)
        module_branch = module_and_branch_info[:module_branch_idh].create_object()

        unless branch_cmp_template = get_branch_template(module_branch,cmp_template)
          raise Error.new("Unexpected that branch_cmp_template is nil")
        end
        create(assembly,branch_cmp_template,antecedent_cmp_template,opts).create_dependency?(opts)
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

      def self.create(assembly,branch_cmp_template,antecedent_cmp_template,opts={})
        klass(assembly,branch_cmp_template,antecedent_cmp_template,opts).new(assembly,branch_cmp_template,antecedent_cmp_template)
      end

      def initialize(assembly,branch_cmp_template,antecedent_cmp_template)
        @assembly = assembly
        @branch_cmp_template = branch_cmp_template
        @antecedent_cmp_template = antecedent_cmp_template
      end

      def self.klass(assembly,cmp_template,antecedent_cmp_template,opts={})
        #Link #TODO: stub
        Simple
      end

      class Simple < self
        def create_dependency?(opts={})
          DTK::Dependency::Simple.create_dependency?(@branch_cmp_template,@antecedent_cmp_template)
        end
      end

      class Link < self
        def create_dependency?(opts={})
          #TODO: stub
          if link_def_link = matching_link_def_link?()
            pp [:matching_link_def_link?,link_def_link]
          end
        end
       private
        def matching_link_def_link?()
          antec_component_type = @antecedent_cmp_template.get_field?(:component_type)
          matches = @branch_cmp_template.get_link_def_links().select do |r|
            r[:remote_component_type] == antec_component_type
          end
          if matches.size > 1
            raise Error.new("Not implemented: case where matching_link_def_link? returns multiple matches")
          end
          matches.first
        end
      end
    end
  end
end; end
