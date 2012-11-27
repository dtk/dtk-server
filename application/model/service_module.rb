r8_require('module_mixins')
r8_nested_require('service_module','service_add_on')
module DTK
  class ServiceModule < Model
    r8_nested_require('service_module','global_module_refs')

    extend ModuleClassMixin
    include ModuleMixin

    def self.model_type()
      :service_module
    end

    def self.list(mh,opts={})
      library_idh = opts[:library_idh]
      lib_filter = (library_idh ? [:eq, :library_library_id, library_idh.get_id()] : [:neq, :library_library_id, nil])
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => lib_filter
      }
      get_objs(mh,sp_hash)
    end

    def list_assembly_templates()
      sp_hash = {
        :cols => [:module_branches]
      }
      mb_idhs = get_objs(sp_hash).map{|r|r[:module_branch].id_handle()}
      filter = [:oneof, :module_branch_id,mb_idhs.map{|idh|idh.get_id()}]
      Assembly.list_from_library(model_handle(:component),:filter => filter)
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

    def get_module_branches()
      Model.get_objs(model_handle.createMH(:module_branch),{:cols => [:module_branches]}).map{|r|r[:module_branch]}
    end

    #creates workspace branch (if needed) and related objects from library one
    def create_workspace_branch?(proj,version,library_idh=nil,library_mb=nil)
      needed_cols = (library_idh.nil? ? [:library_library_id,:display_name] : [:display_name])
      update_object!(*needed_cols)
      module_name = module_name()
      library_idh ||= id_handle(:model_name => :library, :id => self[:library_library_id])

      #get library branch if needed
      library_mb ||= get_library_module_branch(version)

      #create module branch for workspace if needed and push it to repo server
      workspace_mb = library_mb.create_workspace_branch?(:service_module,proj)
      
      #get repo info
      sp_hash = {
        :cols => [:id, :repo_name],
        :filter => [:eq, :id, workspace_mb[:repo_id]]
      }
      repo = Model.get_obj(model_handle(:repo),sp_hash)
      module_info = {:workspace_branch => workspace_mb[:branch]}
      ModuleRepoInfo.new(repo,module_name,module_info,library_idh)
    end

    def update_model_from_clone_changes_aux?(diffs_summary,module_branch)
      update_object!(:library_library_id,:display_name)
      library_idh = id_handle(:model_name => :library, :id => self[:library_library_id])
      self.class.create_assembly_meta_info?(library_idh,module_branch,module_name())
    end
    private :update_model_from_clone_changes_aux?

    def promote_to_library__meta_changes(diffs,ws_branch,lib_branch)
      Log.error("Need to write promote_to_library__meta_changes for service module")
    end
    private :promote_to_library__meta_changes

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
      assembly_templates = list_assembly_templates()
      return ret if assembly_templates.empty?
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:oneof, :ancestor_id, assembly_templates.map{|r|r[:id]}]
      }
      Model.get_objs(model_handle(:component),sp_hash)
    end 

    def self.create_library_module_obj(library_idh,module_name,config_agent_type,version=nil)
      if module_exists?(library_idh,module_name)
        raise ErrorUsage.new("Module (#{module_name}) cannot be created since it exists already")
      end

      repo = create_empty_repo_and_local_clone(library_idh,module_name,module_type(),:delete_if_exists => true)
      module_and_branch_info = create_lib_module_and_branch_obj?(library_idh,repo.id_handle(),module_name,version)
      module_and_branch_info[:module_idh]
    end

   private
    def self.import_postprocess(repo,library_idh,module_name,version)
      module_and_branch_info = create_lib_module_and_branch_obj?(library_idh,repo.id_handle(),module_name,version)
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(:repo => repo) #repo added to avoid lookup in create_assembly_meta_info?
      create_assembly_meta_info?(library_idh,module_branch,module_name)
      module_branch_idh
    end

    def export_preprocess(module_branch)
      #get module info for every component in an assembly in the service module
      module_info = get_component_modules_info(module_branch)

      #check that all component modules are linked to a remote component module
      unlinked_mods = module_info.select{|r|r[:repo][:remote_repo_name].nil?}
      unless unlinked_mods.empty?
        raise ErrorUsage.new("Cannot export a service module that refers to component modules (#{unlinked_mods.map{|r|r[:display_name]}.join(",")}) not already exported")
      end
      GlobalModelRefs.serialize_and_save_to_repo(module_info,module_branch)
    end

    #returns [module_branch,component_modules]
    def get_component_modules_info(module_branch)
      filter = [:eq, :module_branch_id,module_branch[:id]]
      component_templates = Assembly.get_component_templates(model_handle(:component),filter)
      mb_mh = model_handle(:module_branch)
      cmp_module_branch_idhs = component_templates.map{|r|r[:module_branch_id]}.uniq.map{|id|mb_mh.createIDH(:id => id)}
      ModuleBranch.get_component_modules_info(cmp_module_branch_idhs)
    end

    def self.create_assembly_meta_info?(library_idh,module_branch,module_name)
      module_branch_idh = module_branch.id_handle()
      assembly_meta_info = Assembly.meta_filename_path_info()
      add_on_meta_info = ServiceAddOn.meta_filename_path_info()
      depth = [assembly_meta_info[:path_depth],add_on_meta_info[:path_depth]].max
      files = RepoManager.ls_r(depth,{:file_only => true},module_branch)

      ndx_ports = Hash.new
      files.select{|f|f =~ assembly_meta_info[:regexp]}.each do |meta_file|
        json_content = RepoManager.get_file_content({:path => meta_file},module_branch)
        hash_content = JSON.parse(json_content)
        assemblies_hash = hash_content["assemblies"].values.inject(Hash.new) do |h,assembly_info|
          h.merge(assembly_ref(module_name,assembly_info["name"]) => assembly_info)
        end
        node_bindings_hash = hash_content["node_bindings"]
        import_info = Assembly.import(library_idh,module_branch_idh,module_name,assemblies_hash,node_bindings_hash)
        if import_info[:ndx_ports]
          ndx_ports.merge!(import_info[:ndx_ports])
        end
      end
      files.select{|f| f =~ add_on_meta_info[:regexp]}.each do |meta_file|
        json_content = RepoManager.get_file_content({:path => meta_file},module_branch)
        hash_content = JSON.parse(json_content)
        ports = ndx_ports.values
        ServiceAddOn.import(library_idh,module_name,meta_file,hash_content,ports)
      end
    end

    def self.assembly_ref(module_name,assembly_name)
      #TODO: right now cannot change because node bdings in assembly.json hard coded to this. Need to check if any ambiguity
      #if have module name with hyphen
      "#{module_name}-#{assembly_name}"
    end
  end
end
