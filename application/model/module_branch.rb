r8_require('branch_names')
module DTK
  class ModuleBranch < Model
    include BranchNamesMixin
    extend BranchNamesClassMixin
    #virtual columns
    def prety_print_version()
      self[:version]||"master"
    end

    #####    
    def self.update_library_from_workspace?(ws_branches)
      ret = Array.new
      return ret if ws_branches.empty?
      sample_ws_branch = ws_branches.first
      type = sample_ws_branch.update_object!(:type)[:type]
      matching_lib_branches_col = (type == "component_module" ? :matching_component_library_branches : :matching_service_library_branches)
      sp_hash = {
        :cols => [:id,:repo_id,component_module_id_col(),matching_lib_branches_col],
        :filter => [:oneof, :id, ws_branches.map{|r|r.id_handle().get_id()}]
      }
      matching_lib_branches =  get_objs(sample_ws_branch.model_handle(),sp_hash)
pp [:matching_lib_branches, matching_lib_branches]
       matching_lib_branches
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
        h[r[:id]] ||= r
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
      assigns[:version] = version if version
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
