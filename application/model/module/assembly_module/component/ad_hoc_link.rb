module DTK; class AssemblyModule
  class Component
    class AdHocLink < self
      def self.update(assembly,parsed_adhoc_link_info)
        new(assembly).update(parsed_adhoc_link_info)
      end
      def update(parsed_adhoc_link_info)
        parsed_adhoc_links = parsed_adhoc_link_info.links
        unless  parsed_adhoc_links.size == 1
          raise Error.new("Only implemented #{self}.update when parsed_adhoc_links.size == 1")
        end
        parsed_adhoc_link = parsed_adhoc_links.first

        dep_cmp_template = parsed_adhoc_link_info.dep_component_template
        antec_cmp_template = parsed_adhoc_link_info.antec_component_template

        component_module = dep_cmp_template.get_component_module()
        module_branch = create_assembly_branch?(component_module,:ret_module_branch=>true)

        opts_create_dep = {
          :source_attr_pattern => parsed_adhoc_link.attribute_pattern(:source),
          :target_attr_pattern => parsed_adhoc_link.attribute_pattern(:target),
          :update_dsl => true
        }
        result = create_dependency?(:link,dep_cmp_template,antec_cmp_template,module_branch,opts_create_dep)
        if result[:component_module_updated]
          update_cmp_instances_with_modified_template(component_module,module_branch)
        end
        result
      end

      def create_dependency?(type,cmp_template,antecedent_cmp_template,module_branch,opts={})
        result = Hash.new
        branch_cmp_template = get_branch_template(module_branch,cmp_template)

        if opts[:update_dsl]
          opts[:update_dsl] = {:module_branch => module_branch}
        end
        Model.Transaction do
          result = dependency_class(type).create_dependency?(branch_cmp_template,antecedent_cmp_template,opts)
        end
        result
      end

     private
      def dependency_class(type)
        case type 
          when :simple then DTK::Dependency::Simple 
          when :link then DTK::Dependency::Link
        else
          raise Error.new("Illegal type")
        end
      end

    end
  end
end;end
