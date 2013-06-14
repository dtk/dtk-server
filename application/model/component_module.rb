r8_require('module_mixins')
module DTK
  class ComponentModule < Model
    r8_nested_require('component_module','management')
    r8_nested_require('component_module','parse_to_create_dsl')
    include ManagementMixin
    extend ModuleClassMixin
    include ModuleMixin
    include ParseToCreateDSLMixin

    def get_associated_assembly_templates()
      ndx_ret = Hash.new
      get_objs(:cols => [:assembly_templates]).each do |r|
        assembly_template = r[:assembly_template]
        ndx_ret[assembly_template[:id]] ||= Assembly::Template.create_as(assembly_template)
      end
      ndx_ret.values
    end

    def get_aug_associated_component_templates()
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
        component = r[:component]
        ndx_ret[component[:id]] ||= component
      end
     ndx_ret.values
    end

    ##
    # Returnes versions for specified module
    #
    def versions()
      get_objs(:cols => [:version_info]).collect { |v_info| { :version => ModuleBranch.version_from_version_field(v_info[:module_branch][:version]) } }
    end

    def info_about(about)
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

    def self.get_all_workspace_library_diffs(mh)
      #TODO: not treating versions yet and removing modules wheer component not in workspace
      #TODO: much more efficeint is use bulk version 
      modules = get_objs(mh,{:cols => [:id,:display_name]})
      modules.map do |module_obj|
        diffs = module_obj.workspace_library_diffs()
        {:name => module_obj.pp_module_name(), :id => module_obj[:id], :has_diff => !diffs.empty?} if diffs
      end.compact.sort{|a,b|a[:name] <=> b[:name]}
    end

    def module_branches()
      self.update_object!(:module_branches)
      self[:module_branch]
    end

    def get_repos()
      get_objs_helper(:repos,:repo)
    end

    def workspace_library_diffs(version=nil)
      unless ws_branch = get_module_branch_matching_version(version)
        return nil
      end

      #check that there is a library branch
      unless lib_branch =  find_branch(:library,matching_branches)
        raise Error.new("No library version exists for module (#{pp_module_name(version)}); try using create-new-version")
      end

      unless lib_branch[:repo_id] == ws_branch[:repo_id]
        raise Error.new("Not supporting case where promoting workspace to library branch when branches are on two different repos")
      end

      repo = id_handle(:model_name => :repo, :id => lib_branch[:repo_id]).create_object()
      repo.diff_between_library_and_workspace(lib_branch,ws_branch)
    end

    def get_associated_target_instances()
      get_objs_uniq(:target_instances)
    end

   private
    def config_agent_type_default()
      :puppet
    end
    def export_preprocess(branch)
      #noop
    end
  end
end
