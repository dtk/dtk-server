r8_require('branch_names')
module DTK
  class ModuleBranch < Model
    include BranchNamesMixin
    extend BranchNamesClassMixin

    #this adds library branch from this, which is a workspace branch
    def add_library_branch?(new_lib_branch_name)
      RepoManager.add_branch_and_push_to_origin?(new_lib_branch_name,self)
    end

    #this adds workspace branch from this, which is a library branch
    def add_workspace_branch?(new_ws_branch_name)
      RepoManager.add_branch_and_push_to_origin?(new_ws_branch_name,self)
    end

    def serialize_and_save_to_repo(file_path,hash_content)
      content = JSON.pretty_generate(hash_content)
      RepoManager.add_file({:path => file_path},content,self)
    end

    def self.update_library_from_workspace?(ws_branches,opts={})
      ws_branches = [ws_branches] unless ws_branches.kind_of?(Array)
      ret = Array.new
      return ret if ws_branches.empty?
      if opts[:ws_branch_augmented]
        matching_branches = ws_branches
      else
        sample_ws_branch = ws_branches.first
        type = sample_ws_branch.update_object!(:type)[:type]
        sp_hash = {
          :cols => cols_for_matching_library_branches(type),
          :filter => [:oneof, :id, ws_branches.map{|r|r.id_handle().get_id()}]
        }
        matching_branches =  get_objs(sample_ws_branch.model_handle(),sp_hash)
      end
      if matching_branches.find{|r|r[:library_module_branch][:repo_id] != r[:repo_id]}
        raise Error.new("Not implemented: case when ws and library branch differ in refering to distinct repos")
      end
      matching_branches.map{|augmented_branch|update_library_from_workspace_aux?(augmented_branch)}
    end

    def self.cols_for_matching_library_branches(type)
      matching_lib_branches_col = (type.to_s == "component_module" ? :matching_component_library_branches : :matching_service_library_branches)
      [:id,:repo_id,:version,:branch,component_module_id_col(),matching_lib_branches_col]
    end

    def self.get_component_modules_info(module_branch_idhs)
      ret = Array.new
      return ret if module_branch_idhs.nil?
      sp_hash = {
        :cols => [:component_module_info],
        :filter => [:oneof,:id,module_branch_idhs.map{|idh|idh.get_id()}]
      }
      sample_mb_idh = module_branch_idhs.first
      get_objs(sample_mb_idh.createMH(),sp_hash).map do |r|
        r[:component_module].merge(:repo => r[:repo])
      end
    end

    class << self
      def version_field(version=nil)
        version || "master"
      end

      def get_augmented_workspace_branch(module_obj,version=nil)
        sp_hash = {
          :cols => cols_for_matching_library_branches(module_obj.model_name),
          :filter => [:and,[:eq, ModuleBranch.component_module_id_col(),module_obj.id()], 
                      [:eq,:is_workspace,true],
                      [:eq,:version,version_field(version)]]
        }
        aug_ws_branch_rows = get_objs(module_obj.model_handle(:module_branch),sp_hash)
        if aug_ws_branch_rows.empty?
          raise ErrorUsage.new("Component module workspace (#{module_obj.pp_module_name(version)}) does not exist")
        elsif aug_ws_branch_rows.size > 1
          raise Error.new("error in finding unique workspace branch from component module (#{module_obj.pp_module_name(version)})")
        end
        aug_ws_branch_rows.first
      end

     private
      def update_library_from_workspace_aux?(augmented_branch)
        lib_branch_obj = augmented_branch[:library_module_branch]
        lib_branch_augment = {
          :workspace_module_branch => Aux::hash_subset(augmented_branch,[:id,:repo_id]),
        }
        ret = lib_branch_obj.merge(lib_branch_augment)
        ws_branch_name = augmented_branch[:branch]
        #determine if there is any diffs between workspace and library branches
        diff = RepoManager.diff(ws_branch_name,lib_branch_obj)
        diff_summary = diff.ret_summary()
        if diff_summary.no_diffs?()
          return ret
        end
        unless diff_summary.no_added_or_deleted_files?()
          #find matching implementation and modify file assets
          augmented_branch[:implementation].modify_file_assets(diff_summary)
        end
        if diff_summary.meta_file_changed?()
          component_meta_file = ComponentMetaFile.create_meta_file_object(augmented_branch[:repo],augmented_branch[:implementation])
          component_meta_file.update_model()
        end

        #update the repo
        RepoManager.merge_from_branch(ws_branch_name,lib_branch_obj)
        RepoManager.push_implementation(lib_branch_obj)
        ret
      end
    end

    def create_component_workspace_branch?(project)
      cmp_module_id_col = component_module_id_col()
      update_object!(cmp_module_id_col,:version,:repo_id,:type)

      ref = branch = workspace_branch_name(project)
      match_assigns = {
        cmp_module_id_col => self[cmp_module_id_col],
        :project_id =>  project.id_handle.get_id(),
        :version => self[:version]
      }
      other_assigns = {
        :display_name => branch,
        :branch => branch,
        :repo_id => self[:repo_id],
        :is_workspace => true,
        :type => self[:type]

      }
      mb_idh = Model.create_from_row?(model_handle,ref,match_assigns,other_assigns)
      mb_idh.create_object().merge(match_assigns).merge(other_assigns)
    end

    def self.get_component_workspace_branches(node_idhs)
      sp_hash = {
        :cols => [:id,:disply_name,:component_ws_module_branches],
        :filter => [:oneof, :id, node_idhs.map{|idh|idh.get_id()}]
      }
      sample_node_idh = node_idhs.first()
      node_rows = get_objs(sample_node_idh.createMH(),sp_hash)
      #get rid of dups 
      node_rows.inject(Hash.new) do |h,r|
        module_branch = r[:module_branch]
        h[module_branch[:id]] ||= module_branch
        h
      end.values
    end

    def self.ret_lib_create_hash(parent_model_name,library_idh,repo_idh,version=nil)
      branch =  library_branch_name(library_idh,version)
      assigns = {
        :display_name => branch,
        :branch => branch,
        :repo_id => repo_idh.get_id(),
        :is_workspace => false,
        :type => parent_model_name.to_s
      }
      assigns[:version] = version||BranchNameDefaultVersion
      ref = branch
      {ref => assigns}
    end

    def repo_and_branch()
      cols = (self[:repo] ? [:branch] : [:branch,:repo_id])
      update_object!(*cols)
      unless self[:repo]
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:eq,:id,self[:repo_id]]
        }
        repo = Model.get_obj(model_handle(:repo),sp_hash)
        self[:repo] = repo[:display_name]
      end
      [self[:repo],self[:branch]]
    end

    #in case we change what schema the module and branch objects under
    def self.service_module_id_col()
      :service_id
    end
    def service_module_id_col()
      self.class.service_module_id_col()
    end
    def service_module_id()
      self[service_module_id_col()]
    end
    def self.component_module_id_col()
      :component_id
    end
    def component_module_id_col()
      self.class.component_module_id_col()
    end
    def component_module_id()
      self[component_module_id_col()]
    end
  end
end
