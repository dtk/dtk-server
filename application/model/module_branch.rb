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
    def create_component_workspace_branch?(project_idh)
      cmp_module_id_col = component_module_id_col()
      cmp_module_id = update_object!(cmp_module_id_col,:version)[cmp_module_id_col]
      #check if there is a matching branch for workspace created already
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, 
                    [:eq, cmp_module_id_col, cmp_module_id],
                    [:eq, :project_id, project_idh.get_id()],
                    [:eq, :vesrion, self[:version]]
                   ]
      }
      matching_rows = Model.get_objs(model_handle(),sp_hash)
      if matching_rows.size == 1
        matching_rows.first.id_handle()
      elsif matching_rows.size > 1
        raise Error.new("Unexpected result: more than one match when looking for workspace")
      else
        raise Error.new("need to write creating new model branch")
      end
    end

    def self.get_workspace_module_branches(node_idhs)
      sp_hash = {
        :cols => [:id,:disply_name,:component_ws_module_branches],
        :filter => [:oneof, :id, node_idhs.map{|idh|idh.get_id()}]
      }
      sample_node_idh = node_idhs.first()
      node_rows = get_obj(sample_node_idh.createMH(),sp_hash)
      node_rows.map{|r|r[:module_branch].id_handle()}
    end

    def self.ret_create_hash(parent_model_name,library_idh,repo_idh,version=nil)
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
