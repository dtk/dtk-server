r8_require('branch_names')
module XYZ
  class ModuleBranch < Model
    include BranchNamesMixin
    extend BranchNamesClassMixin
    #virtual columns
    def prety_print_version()
      self[:version]||"master"
    end
    
    def self.ret_hash_for_create(library_idh,version=nil)
      ret = {
        :branch => library_branch_name(library_idh,version),
        :is_workspace => false
      }
      ret[:version] = version if version
      ret
    end
  end
end
