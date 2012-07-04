r8_require('branch_names')
module DTK
  class ModuleBranch < Model
    include BranchNamesMixin
    extend BranchNamesClassMixin

    def self.update_library_from_workspace?(ws_branches)
      ret = Array.new
      return ret if ws_branches.empty?
      sample_ws_branch = ws_branches.first
      type = sample_ws_branch.update_object!(:type)[:type]
      matching_lib_branches_col = (type == "component_module" ? :matching_component_library_branches : :matching_service_library_branches)
      sp_hash = {
        :cols => [:id,:repo_id,:version,:branch,component_module_id_col(),matching_lib_branches_col],
        :filter => [:oneof, :id, ws_branches.map{|r|r.id_handle().get_id()}]
      }
      matching_branches =  get_objs(sample_ws_branch.model_handle(),sp_hash)
      if matching_branches.find{|r|r[:library_module_branch][:repo_id] != r[:repo_id]}
        raise Error.new("Not implemented: case when ws and library branch being diffed in different repos")
      end
      matching_branches.map{|augmented_branch|update_library_from_workspace_aux?(augmented_branch)}
    end

    class << self
      private
      def update_library_from_workspace_aux?(augmented_branch)
pp augmented_branch[:component_module][:display_name]
        ret = lib_branch_obj = augmented_branch[:library_module_branch]
        ws_branch_name = augmented_branch[:branch]
        #determine if there is any diffs between workspace and library branches
        diff = RepoManager.diff(ws_branch_name,lib_branch_obj)
        diff_summary = diff.ret_summary()
        if diff_summary.no_diffs?()
          return ret
        end
pp 'some change'
        unless diff_summary.no_added_or_deleted_files?()
          #find matching implementation and modify file assets
          augmented_branch[:implementation].modify_file_assets(diff_summary)
        end
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
      Model.create_from_row?(model_handle,ref,match_assigns,other_assigns)
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
