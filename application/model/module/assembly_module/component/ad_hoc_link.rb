module DTK; class AssemblyModule
  class Component
    class AdHocLink < self
      def self.update(assembly,parsed_adhoc_link_info)
        parsed_adhoc_links = parsed_adhoc_link_info.links
        unless  parsed_adhoc_links.size == 1
          raise Error.new("Only implented #{self}.update when  parsed_adhoc_links.size == 1")
        end
        parsed_adhoc_link = parsed_adhoc_links.first

        dep_cmp_template = parsed_adhoc_link_info.dep_component_template
        antec_cmp_template = parsed_adhoc_link_info.antec_component_template

        component_module = dep_cmp_template.get_component_module()
        module_branch = create_assembly_branch?(assembly,component_module,:ret_module_branch=>true)

        opts_create_dep = {
          :source_attr_pattern => parsed_adhoc_link.attribute_pattern(:source),
          :target_attr_pattern => parsed_adhoc_link.attribute_pattern(:target),
          :update_dsl => true
        }
        result = create_dependency?(:link,assembly,dep_cmp_template,antec_cmp_template,module_branch,opts_create_dep)
        if result[:component_module_updated]
          modify_cmp_instances_with_new_parents(assembly,component_module,module_branch)
        end
        result
      end

      def self.create_dependency?(type,assembly,cmp_template,antecedent_cmp_template,module_branch,opts={})
        result = Hash.new
        unless branch_cmp_template = get_branch_template(module_branch,cmp_template)
          raise Error.new("Unexpected that branch_cmp_template is nil")
        end
        if opts[:update_dsl]
          opts[:update_dsl] = {:module_branch => module_branch}
        end
        Model.Transaction do
          result = dependency_class(type).create_dependency?(branch_cmp_template,antecedent_cmp_template,opts)
        end
        result
      end

     private
      def self.get_branch_template(module_branch,cmp_template)
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:component_type],
          :filter => [:and,[:eq,:module_branch_id,module_branch.id()],
                      [:eq,:type,'template'],
                      [:eq,:node_node_id,nil],
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
end;end
