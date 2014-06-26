module DTK
  class ComponentModule < Model
    r8_nested_require('component','dsl_mixin')
    r8_nested_require('component','dsl')

    r8_nested_require('component','version_context_info')
    r8_nested_require('component','delete_mixin')

    include DeleteMixin
    extend ModuleClassMixin
    include ModuleMixin
    include DSLMixin

    def get_associated_assembly_templates()
      ndx_ret = Hash.new
      get_objs(:cols => [:assembly_templates]).each do |r|
        assembly_template = r[:assembly_template]
        ndx_ret[assembly_template[:id]] ||= Assembly::Template.create_as(assembly_template)
      end
      ndx_ret.values
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
          display_name = Component::Template.component_type_print_form(cmp[:component_type],Opts.new(:no_module_name => true))
          {:id => cmp[:id], :display_name => display_name,:version => branch.version_print_form() }
        end.sort{|a,b|"#{a[:version]}-#{a[:display_name]}" <=>"#{b[:version]}-#{b[:display_name]}"}
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

        ret = []
        results.each do |el|
          title_elements = [el[:node][:display_name],el[:component_instance][:display_name]]
          title_elements.unshift(el[:assembly][:display_name]) if el[:assembly]
          ret << { 
            :id => el[:component_instance][:id], 
            :display_name => title_elements.join('/'), 
            :version => ModuleBranch.version_from_version_field(el[:component_instance][:version])
          }
        end

        return ret
      else
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")        
      end
    end

    def self.model_type()
      :component_module
    end
    def self.component_type()
      :puppet #hardwired
    end
    def component_type()
      :puppet #hardwired
    end

    def self.module_specific_type(config_agent_type)
      config_agent_type
    end

    # Method will check if given component modules are present on the system
    # returns [missing_modules, found_modules]
    def self.cross_reference_modules(opts, required_modules, service_namespace)
      project_idh = opts.required(:project_idh)

      required_modules ||= []
      req_names = required_modules.collect { |m| m['component_module']}

      sp_hash = {
        :cols => [:id, :display_name, :remote_repos].compact,
        :filter => [:and,[:oneof, :display_name, req_names],[:eq, :project_project_id, project_idh.get_id()]]
      }
      mh = project_idh.createMH(model_type())
      installed_modules = get_objs(mh,sp_hash)

      missing_modules   = []
      found_modules = []

      required_modules.each do |r_module|
        name      = r_module["component_module"]
        version   = r_module["version_info"]
        namespace = r_module["remote_namespace"]

        is_found = installed_modules.find do |i_module|
          name.eql?(i_module[:display_name]) and 
          ModuleVersion.versions_same?(version, i_module.fetch(:module_branch,{})[:version]) and
          (namespace.nil? or namespace.eql?(i_module.fetch(:repo_remote,{})[:repo_namespace]))
        end
        data = { :name => name, :version => version, :namespace => namespace||service_namespace}
        if is_found
        found_modules << data 
        else
          missing_modules << data
        end
      end

      [missing_modules, found_modules]
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

   private
    def config_agent_type_default()
      :puppet
    end

    def publish_preprocess_raise_error?(module_branch_obj)
      unless get_field?(:dsl_parsed)
        raise ErrorUsage.new("Unable to publish module that has parsing errors. Please fix errors and try to publish again.")
      end
    end
    
  end
end
