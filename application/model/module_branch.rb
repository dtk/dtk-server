r8_require('branch_names')
module XYZ
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
  end
end
