r8_require('module_mixins')
#TODO: until move import_export_common under service module
r8_nested_require('assembly','import_export_common')
module DTK
  class ServiceModule < Model
    r8_nested_require('service_module','global_module_refs')
    r8_nested_require('service_module','dsl')
    r8_nested_require('service_module','component_version')

    extend ModuleClassMixin
    include ModuleMixin
    extend DSLClassMixin
    include ComponentVersionMixin

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

    def get_referenced_component_modules()
      ret = Array.new
      cmp_refs = get_referenced_component_refs()
      return ret if cmp_refs.empty?
      project = get_project()
      ComponentRef.get_referenced_component_modules(project,cmp_refs)
    end

    ### end: get methods

    def self.model_type()
      :service_module
    end

    def self.delete(idh)
      module_obj = idh.create_object().update_object!(:display_name,:project_project_id)
      module_name =  module_obj[:display_name]
      assoc_assemblies = module_obj.get_associated_target_instances()
      unless assoc_assemblies.empty?
        assembly_ids = assoc_assemblies.map{|a|a[:id]}
        raise ErrorUsage.new("Cannot delete a module if one or more of its instances exist in a target (#{assembly_ids.join(',')})")
      end
      repos = module_obj.get_repos()
      repos.each{|repo|RepoManager.delete_repo(repo)}
      delete_instances(repos.map{|repo|repo.id_handle()})

      assemblies = idh.create_object().get_assemblies()
      #need to explicitly delete nodes since nodes' parents are not the assembly
      Assembly::Template.delete_assemblies_nodes(assemblies.map{|a|a.id_handle()})

      delete_instance(idh)
      {:module_name => module_name}
    end

    #MOD_RESTRUCT: TODO: when deprecate self.list__library_parent(mh,opts={}), sub .list__project_parent for this method
    def self.list(mh,opts)
      if project_id = opts[:project_idh]
        ndx_ret = list__library_parent(mh,opts).inject(Hash.new){|h,r|h.merge(r[:display_name] => r)}
        list__project_parent(mh,opts[:project_idh]).each{|r|ndx_ret[r[:display_name]] ||= r}
        ndx_ret.values.sort{|a,b|a[:display_name] <=> b[:display_name]}
      else
        list__library_parent(mh,opts)
      end
    end
    def self.list__project_parent(mh,project_idh)
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => [:eq, :project_project_id, project_idh.get_id()]
      }
      get_objs(mh,sp_hash)
    end
    #MOD_RESTRUCT: TODO: deprecate below for above
    def self.list__library_parent(mh,opts={})
      library_idh = opts[:library_idh]
      lib_filter = (library_idh ? [:eq, :library_library_id, library_idh.get_id()] : [:neq, :library_library_id, nil])
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => lib_filter
      }
      get_objs(mh,sp_hash)
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
      Assembly::Template.get(model_handle(:component),opts)
    end

    def info_about(about)
      case about
        when :assemblies
        mb_idhs = get_objs(:cols => [:module_branches]).map{|r|r[:module_branch].id_handle()}
        filter = [:oneof, :module_branch_id,mb_idhs.map{|idh|idh.get_id()}]
        Assembly::Template.list(model_handle(:component),:filter => filter)
      else
        raise ErrorUsage.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
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

    def update_model_from_clone_changes_aux?(diffs_summary,module_branch,version=nil)
      project_idh = get_project().id_handle()
      update_object!(:display_name)
      #TODO: for more efficiency can push in diffs_summary to below
      self.class.update_model_from_dsl(project_idh,module_branch,module_name())
    end
    private :update_model_from_clone_changes_aux?

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

    def get_associated_target_instances()
      ret = Array.new
      assembly_templates = get_assembly_templates()
      return ret if assembly_templates.empty?
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:oneof, :ancestor_id, assembly_templates.map{|r|r[:id]}]
      }
      Model.get_objs(model_handle(:component),sp_hash)
    end 

    def self.create_workspace_module_obj(project,module_name,config_agent_type,version=nil)
      project_idh = project.id_handle()
      if module_exists?(project_idh,module_name)
        raise ErrorUsage.new("Module (#{module_name}) cannot be created since it exists already")
      end
      ws_branch = ModuleBranch.workspace_branch_name(project,version)
      create_opts = {
        :create_branches => [ws_branch],
        :delete_if_exists => true
      }
      repo = create_empty_workspace_repo(project_idh,module_name,module_type(),create_opts)
      module_and_branch_info = create_ws_module_and_branch_obj?(project,repo.id_handle(),module_name,version)
      module_and_branch_info[:module_idh]
    end

   private
    def self.import_postprocess(project,repo,module_name,version)
      module_and_branch_info = create_ws_module_and_branch_obj?(project,repo.id_handle(),module_name,version)
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(:repo => repo) #repo added to avoid lookup in create_assemblies_dsl
      update_model_from_dsl(project.id_handle(),module_branch,module_name)
      module_branch_idh
    end

    def export_preprocess(module_branch)
      #get module info for every component in an assembly in the service module
      module_info = get_component_modules_info(module_branch)

      #check that all component modules are linked to a remote component module
      unlinked_mods = module_info.reject{|r|r[:repo].linked_remote?()}
      unless unlinked_mods.empty?
        raise ErrorUsage.new("Cannot export a service module that refers to component modules (#{unlinked_mods.map{|r|r[:display_name]}.join(",")}) not already exported")
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
