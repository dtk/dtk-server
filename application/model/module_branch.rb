r8_require('branch_names')
module DTK
  class ModuleBranch < Model
    include BranchNamesMixin
    extend BranchNamesClassMixin
    #virtual columns
    def prety_print_version()
      self[:version]||"master"
    end
    
    def self.ret_create_hash(library_idh,repo_idh,version=nil)
      branch =  library_branch_name(library_idh,version)
      assigns = {
        :display_name => branch,
        :branch => branch,
        :repo_id => repo_idh.get_id(),
        :is_workspace => false,
        :type => "service_module"
      }
      assigns[:version] = version if version
      ref = branch
      {ref => assigns}
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
