#TODO: until move import_export_common under service module
r8_nested_require('../assembly','import_export_common')
module DTK
  class ServiceModule < Model
    r8_nested_require('service','component_module_ref') 
    r8_nested_require('service','component_module_refs') 
    r8_nested_require('service','dsl')

    extend ModuleClassMixin
    include ModuleMixin
    extend DSLClassMixin
    include DSLMixin
    include ComponentModuleRefsMixin

    ### standard get methods
    def get_assemblies()
      get_objs_helper(:assemblies,:component)
    end

    def get_augmented_assembly_nodes()
      get_objs_helper(:assembly_nodes,:node,:augmented => true)
    end

    def get_referenced_component_refs()
      ndx_ret = Hash.new
      get_objs(:cols => [:component_refs]).each do |r|
        cmp_ref = r[:component_ref]
        ndx_ret[cmp_ref[:id]] ||= cmp_ref
      end
      ndx_ret.values
    end

    def get_referenced_component_modules(opts=Opts.new)
      ret = Array.new
      cmp_refs = get_referenced_component_refs()
      return ret if cmp_refs.empty?
      project = get_project()
      ret = ComponentRef.get_referenced_component_modules(project,cmp_refs)

      if opts.array(:detail_to_include).include?(:versions)
        ndx_versions = get_component_module_refs().version_objs_indexed_by_modules()
        
        ret.each do |mod|
          if version_obj = ndx_versions[mod.module_name()]
            mod[:version] = version_obj
          end
        end
      end
      ret
    end

    ### end: get methods

    def self.model_type()
      :service_module
    end

    def delete_object()
      assembly_templates = get_assembly_templates()

      assoc_assemblies = self.class.get_associated_target_instances(assembly_templates)
      unless assoc_assemblies.empty?
        assembly_names = assoc_assemblies.map{|a|a[:display_name]}
        raise ErrorUsage.new("Cannot delete a module if one or more of its assembly instances exist in a target (#{assembly_names.join(',')})")
      end
      repos = get_repos()
      repos.each{|repo|RepoManager.delete_repo(repo)}
      delete_instances(repos.map{|repo|repo.id_handle()})

      #need to explicitly delete nodes since nodes' parents are not the assembly
      Assembly::Template.delete_assemblies_nodes(assembly_templates.map{|a|a.id_handle()})

      delete_instance(id_handle())
      {:module_name => module_name}
    end

    def delete_version(version)
      module_branch  = get_module_branch_matching_version(version)
      raise ErrorUsage.new("Version '#{version}' for specified component module does not exist") unless module_branch

      assembly_templates = module_branch.get_assemblies()
      assoc_assemblies = self.class.get_associated_target_instances(assembly_templates)
      unless assoc_assemblies.empty?
        assembly_names = assoc_assemblies.map{|a|a[:display_name]}
        raise ErrorUsage.new("Cannot delete a module if one or more of its assembly instances exist in a target (#{assembly_names.join(',')})")
      end

      Assembly::Template.delete_assemblies_nodes(assembly_templates.map{|a|a.id_handle()})

      id_handle = module_branch.id_handle()
      module_branch.delete_instance(id_handle)
      {:module_name => module_name}
    end

    def get_assembly_templates()
      sp_hash = {
        :cols => [:module_branches]
      }
      mb_idhs = get_objs(sp_hash).map{|r|r[:module_branch].id_handle()}
      opts = {
        :filter => [:oneof, :module_branch_id,mb_idhs.map{|idh|idh.get_id()}]
      }
      if project = get_project()
        opts.merge!(:project_idh => project.id_handle())
      end
      ndx_ret = Assembly::Template.get(model_handle(:component),opts).inject(Hash.new){|h,r|h.merge(r[:id] => r)}
      Assembly::Template.get_nodes(ndx_ret.values.map{|r|r.id_handle}).each do |node|
        assembly = ndx_ret[node[:assembly_id]]
        (assembly[:nodes] ||= Array.new)  << node
      end
      ndx_ret.values
    end

    def info_about(about)
      case about
       when "assembly-templates".to_sym
        mb_idhs = get_objs(:cols => [:module_branches]).map{|r|r[:module_branch].id_handle()}
        opts = {
          :filter => [:oneof, :module_branch_id,mb_idhs.map{|idh|idh.get_id()}],
          :detail_level => "nodes",
          :no_module_prefix => true
        }
        if project = get_project()
          opts.merge!(:project_idh => project.id_handle())
        end
        Assembly::Template.list(model_handle(:component),opts)
      when :components
        assembly_templates = get_assembly_templates
      else
        raise ErrorUsage.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
    end

    def versions(module_id)
      module_name, remote_versions = nil, []

      # get local versions list and remove master(nil) from list
      local_versions = get_objs(:cols => [:version_info]).collect { |v_info| ModuleBranch.version_from_version_field(v_info[:module_branch][:version]) }.map!{|v| v.nil? ? "CURRENT" : v}
      
      # get all remote modules versions, and take only versions for current service module name
      info = ServiceModule.info(model_handle(), module_id)
      module_name = info[:remote_repos].first[:repo_name].gsub(/\*/,'').strip() unless info[:remote_repos].empty?
      remote_versions = ServiceModule.list_remotes(model_handle).select{|r|r[:display_name]==module_name}.collect{|v_remote| ModuleBranch.version_from_version_field(v_remote[:versions])}.map!{|v| v.nil? ? "CURRENT" : v} if module_name
      
      local_hash  = {:namespace => "local", :versions => local_versions.flatten}
      remote_hash = {:namespace => "remote", :versions => remote_versions}

      versions = [local_hash]
      versions << remote_hash unless remote_versions.empty?

      versions
    end

    def self.get_project_trees(mh)
      sp_hash = {
        :cols => [:id,:display_name,:module_branches]
      }
      sm_branch_info = get_objs(mh,sp_hash)

      ndx_targets = get_ndx_targets(sm_branch_info.map{|r|r[:module_branch].id_handle()})
      mb_idhs = Array.new
      ndx_ret = sm_branch_info.inject(Hash.new) do |h,r|
        module_branch = r[:module_branch]
        mb_idhs << module_branch.id_handle()
        mb_id = module_branch[:id]
        content = SimpleOrderedHash.new(
         [
          {:name => r.pp_module_branch_name(module_branch)},
          {:id => mb_id},
          {:targets => ndx_targets[mb_id]||Array.new},
          {:assemblies => Array.new}
         ])
        h.merge(mb_id => content) 
      end

      filter = [:oneof, :module_branch_id,mb_idhs.map{|idh|idh.get_id()}]
      assembly_mh = mh.createMH(:component)
      Assembly::Template.list(assembly_mh,:filter => filter,:component_info=>true).each do |r|
        index = r[:module_branch_id]
        assemblies = ndx_ret[index][:assemblies]
        assemblies  << SimpleOrderedHash.new([{:name => r[:display_name]}, {:id => r[:id]}, {:nodes => format_for_get_project_trees__nodes(r[:nodes])}])
      end
      ndx_ret.values
    end
    #TODO: use of SimpleOrderedHash above and below was just used to print out in debuging and could be removed
    class << self
      private
      def format_for_get_project_trees__nodes(nodes)
        nodes.map{|n|SimpleOrderedHash.new([{:name => n[:node_name]},{:id => n[:node_id]},{:components => format_for_get_project_trees__cmps(n[:components])}])}
      end

      def format_for_get_project_trees__cmps(cmps)
        cmps.map{|cmp|SimpleOrderedHash.new([{:name => cmp[:component_name]},{:id => cmp[:component_id]},{:description => cmp[:description]}])}
      end
    end

=begin
    def get_ports()
      module_branches = get_module_branches()
      ndx_targets = self.class.get_ndx_targets(module_branches.map{|r|r.id_handle()})
      ndx_ret = Hash.new
      ndx_targets.each_value do |t|

"component_external","component_internal_external")
    end
=end
    #targets indexed by service_module
    def self.get_ndx_targets(sm_branch_idhs)
      #TODO: right now: putting in all targets for all service modules;
      ret = Array.new
      return ret if sm_branch_idhs.empty?
      sm_branch_mh = sm_branch_idhs.first.createMH()
      all_targets = Target.list(sm_branch_mh).map do |r|
        SimpleOrderedHash.new([{:name => r[:display_name]},{:id => r[:id]},{:description => r[:description]}])
      end
      sm_branch_idhs.inject(Hash.new) do |h,sm_branch_idh|
        h.merge(sm_branch_idh.get_id => all_targets)
      end
    end

    def self.find(mh,service_module_name,library_idh=nil)
      lib_filter = library_idh && [:and,:library_library_id,library_idh.get_id()]
      sp_hash = {
        :cols => [:id,:display_name,:library_library_id],
        :filter => [:and, [:eq, :display_name, service_module_name],lib_filter].compact
      }
      rows = get_objs(mh,sp_hash)
      case rows.size
       when 0 then nil
       when 1 then rows.first
       else raise ErrorUsage.new("Cannot find unique service module given service_module_name=#{service_module_name}")
      end
    end

    def self.get_associated_target_instances(assembly_templates)
      ret = Array.new
      return ret if assembly_templates.empty?
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:oneof, :ancestor_id, assembly_templates.map{|r|r[:id]}]
      }
      mh = assembly_templates.first.model_handle(:component)
      get_objs(mh,sp_hash)
    end 

    def pull_from_remote__update_from_dsl(repo, module_and_branch_info)
      info = module_and_branch_info #for succinctness
      module_branch_idh = info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(:repo => repo)

      update_model_from_dsl(module_branch)
    end

    def import__dsl(commit_sha,repo,module_and_branch_info,version, opts = {})
      unless version.nil?
        raise Error.new("Not implemented yet ServiceModule#import__dsl with version not equal to nil")
      end
      info = module_and_branch_info #for succinctness
      module_branch_idh = info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(:repo => repo) #repo added to avoid lookup in update_model_from_dsl
      parsed = update_model_from_dsl(module_branch, opts)
      module_branch.set_sha(commit_sha)
      parsed
    end

   private
    def create_new_version__type_specific(repo_for_new_branch,new_version,opts={})
      project = get_project()
      repo_idh = repo_for_new_branch.id_handle()
      module_and_branch_info = self.class.create_ws_module_and_branch_obj?(project,repo_idh,module_name(),new_version)
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(:repo => repo_for_new_branch) #repo added to avoid lookup in update_model_from_dsl
      update_model_from_dsl(module_branch,opts)
    end

    def update_model_from_clone__type_specific?(commit_sha,diffs_summary,module_branch,version,opts={})
      #TODO: for more efficiency can push in diffs_summary to below
      # opts = {:donot_make_repo_changes => true} #clone operation should push any chanegs to repo
      opts[:donot_make_repo_changes] = true
      update_model_from_dsl(module_branch,opts)
    end

    def export_preprocess(module_branch, module_obj)
      #get module info for every component in an assembly in the service module
      is_parsed   = false
      module_info = get_component_modules_info(module_branch)

      #check that all component modules are linked to a remote component module
      unlinked_mods = module_info.reject{|r|r[:repo].linked_remote?()}
      unless unlinked_mods.empty?
        raise ErrorUsage.new("Cannot export a service module that refers to component modules (#{unlinked_mods.map{|r|r[:display_name]}.join(",")}) not already exported")
      end

      is_parsed = module_obj[:dsl_parsed] if module_obj
      unless is_parsed
        raise ErrorUsage.new("Unable to export module that has parsing errors. Please fix errors and try export again.")
      end
    end

    #returns [module_branch,component_modules]
    def get_component_modules_info(module_branch)
      filter = [:eq, :module_branch_id,module_branch[:id]]
      component_templates = Assembly.get_component_templates(model_handle(:component),filter)
      mb_mh = model_handle(:module_branch)
      cmp_module_branch_idhs = component_templates.map{|r|r[:module_branch_id]}.uniq.map{|id|mb_mh.createIDH(:id => id)}
      ModuleBranch.get_component_modules_info(cmp_module_branch_idhs)
    end

    def self.assembly_ref(module_name,assembly_name)
      #TODO: right now cannot change because node bdings in assembly.json hard coded to this. Need to check if any ambiguity
      #if have module name with hyphen
      "#{module_name}-#{assembly_name}"
    end
  end
end
