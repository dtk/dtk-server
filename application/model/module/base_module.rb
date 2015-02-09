module DTK
  class BaseModule < Model
    r8_nested_require('base_module','update_module')
    r8_nested_require('base_module','version_context_info')

    # TODO: look through r8_nested_require('module'..,) and see which ones should be under instead base_module
    r8_nested_require('module','dsl')
    r8_nested_require('module','node_module_dsl')
    r8_nested_require('module','auto_import')

    r8_nested_require('module','delete_mixin')

    include DeleteMixin
    extend ModuleClassMixin
    extend AutoImport
    include ModuleMixin
    include UpdateModule::Mixin
    extend UpdateModule::ClassMixin

    def get_associated_assembly_templates()
      ndx_ret = Hash.new
      get_objs(:cols => [:assembly_templates]).each do |r|
        assembly_template = r[:assembly_template]
        ndx_ret[assembly_template[:id]] ||= Assembly::Template.create_as(assembly_template)
      end
      Assembly::Template.augment_with_namespaces!(ndx_ret.values)
    end

    # each of the module's component_templates associated with zero or more assembly template component references
    # component refs indexed by component template; plus augmented info for cmp refs; it has form
    # Component::Template:
    #   component_refs:
    #   - ComponentRef:
    #      node: Node
    #      assembly_template: Assembly::Template
    def get_associated_assembly_cmp_refs()
      ndx_ret = Hash.new
      get_objs(:cols => [:assembly_templates]).each do |r|
        component_template = r[:component_template]
        pntr = ndx_ret[component_template[:id]] ||= component_template.merge(:component_refs => Array.new)
        pntr[:component_refs] << r[:component_ref].merge(r.hash_subset(:id,:display_name,:node,:assembly_template))
      end
      ndx_ret.values
    end

    def get_associated_component_instances()
      ndx_ret = Hash.new
      get_objs(:cols => [:component_instances]).each do |r|
        cmp = r[:component]
        cmp[:namespace] = r[:namespace][:display_name] if r[:namespace]
        ndx_ret[cmp[:id]] ||= Component::Instance.create_subclass_object(cmp)
      end
     ndx_ret.values
    end

    def info_about(about, cmp_id=nil)
      case about.to_sym
      when :components
        get_objs(:cols => [:components]).map do |r|
          cmp = r[:component]
          branch = r[:module_branch]
          unless branch.assembly_module_version?()
            display_name = Component::Template.component_type_print_form(cmp[:component_type],Opts.new(:no_module_name => true))
            {:id => cmp[:id], :display_name => display_name,:version => branch.version_print_form() }
          end
        end.compact.sort{|a,b|"#{a[:version]}-#{a[:display_name]}" <=>"#{b[:version]}-#{b[:display_name]}"}
      when :attributes
        results = get_objs(:cols => [:attributes])
        results.delete_if { |e| !(e[:component][:id] == cmp_id.to_i) } if cmp_id && !cmp_id.empty?
        ret = results.inject([]) do |transformed, element|
          attribute = element[:attribute]
          branch = element[:module_branch]
          transformed << { :id => attribute[:id], :display_name => attribute.print_path(element[:component]), :value => attribute[:value_asserted], :version=> branch.version_print_form()}
        end
        return ret.sort{|a,b|a[:display_name] <=> b[:display_name]}
      when :instances
        results = get_objs(:cols => [:component_module_instances_assemblies])
        # another query to get component instances that do not have assembly
        results += get_objs(:cols => [:component_module_instances_node])

        results.map do |el|
          component_instance = el[:component_instance]
          display_name_parts = {
            :node => el[:node][:display_name],
            :component => Component::Instance.print_form(component_instance),
          }
          display_name = "#{display_name_parts[:node]}/#{display_name_parts[:component]}"
          if assembly = el[:assembly]
            assembly_name = assembly[:display_name]
            display_name_parts.merge!(:assembly => assembly_name)
            display_name = "#{assembly_name}/#{display_name}"
          end
          {
            :id => component_instance[:id],
            :display_name => display_name,
            :display_name_parts => display_name_parts,
            :service_instance => display_name_parts[:assembly],
            :node => display_name_parts[:node],
            :component_instance => display_name_parts[:component],
            :version => ModuleBranch.version_from_version_field(component_instance[:version])
          }
        end
      else
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
    end

    def self.module_specific_type(config_agent_type)
      config_agent_type
    end

    def module_branches()
      self.update_object!(:module_branches)
      self[:module_branch]
    end

    # raises exception if more repos found
    def get_repo!()
      repos = get_repos()
      unless repos.size == 1
        raise Error.new("unexpected that number of matching repos is not equal to 1")
      end

      return repos.first()
    end

    def get_repos()
      get_objs_helper(:repos,:repo)
    end

    def get_associated_target_instances()
      get_objs_uniq(:target_instances)
    end

    def config_agent_type_default()
      :puppet
    end

   private

    def publish_preprocess_raise_error?(module_branch_obj)
      # unless get_field?(:dsl_parsed)
      unless module_branch_obj.dsl_parsed?()
        raise ErrorUsage.new("Unable to publish module that has parsing errors. Please fix errors and try to publish again.")
      end
    end

  end
end
