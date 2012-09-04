r8_require('module_mixins')
module DTK
  class ServiceModule < Model
    extend ModuleClassMixin
    include ModuleMixin

    #import from remote
    def self.import(library_idh,remote_module_name,remote_namespace)
      ret = nil
      module_name = remote_module_name
      repo = common_import_steps(library_idh,remote_module_name,remote_namespace)

      module_and_branch_info = create_lib_module_and_branch_obj?(library_idh,repo.id_handle(),module_name)
      create_assembly_meta_info?(library_idh,module_and_branch_info[:module_branch_idh],module_name,repo)
      module_and_branch_info[:module_idh]
    end

    def list_assembly_templates()
      sp_hash = {
        :cols => [:module_branches]
      }
      mb_idhs = get_objs(sp_hash).map{|r|r[:module_branch].id_handle()}
      filter = [:oneof, :module_branch_id,mb_idhs.map{|idh|idh.get_id()}]
      Assembly.list_from_library(model_handle(:component),:filter => filter)
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


    def self.create_library_obj(library_idh,module_name,config_agent_type)
      raise_error_if_library_module_exists(library_idh,module_name)

      repo = create_empty_repo_and_local_clone(library_idh,module_name,module_type(),:delete_if_exists => true)
      module_and_branch_info = create_lib_module_and_branch_obj?(library_idh,repo.id_handle(),module_name)
      module_and_branch_info[:module_idh]
    end

    def self.get_module_branch(library_idh,service_module_name,version=nil)
      sp_hash = {
        :cols => [:id,:display_name,:module_branches],
        :filter => [:and, [:eq, :display_name, service_module_name], [:eq, :library_library_id, library_idh.get_id()]]
      }
      rows =  get_objs(library_idh.create_childMH(module_type()),sp_hash)
      if rows.empty?
        raise ErrorUsage.new("Service module (#{service_module_name}) does not exist")
      end
      version ||= BranchNameDefaultVersion
      version_match_row = rows.find{|r|r[:module_branch][:version] == version}
      version_match_row && version_match_row[:module_branch]
    end

   private
    def self.create_assembly_meta_info?(library_idh,module_branch_idh,module_name,repo)
      depth = 1
      meta_filename_regexp = Assembly.meta_filename_regexp()
      meta_files = RepoManager.ls_r(depth,{:file_only => true},repo).select{|f|f =~ meta_filename_regexp}
      meta_files.map do |meta_file|
        json_content = RepoManager.get_file_content({:path => meta_file},repo)
        hash_content = JSON.parse(json_content)
        assemblies_hash = hash_content["assemblies"]
        node_bindings_hash = hash_content["node_bindings"]
        Assembly.import(library_idh,module_branch_idh,module_name,assemblies_hash,node_bindings_hash)
      end
    end
  end
end
