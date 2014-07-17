r8_nested_require('mixins','remote')
r8_nested_require('mixins','create')
r8_nested_require('mixins','gitolite')
r8_nested_require('utils','list_method')

module DTK
  class ModuleRepoInfo < Hash
    def initialize(repo,module_name,module_idh,branch_obj,version=nil)
      super()
      repo_name = repo.get_field?(:repo_name)
      hash = {
        :repo_id => repo[:id],
        :repo_name => repo_name,
        :module_id => module_idh.get_id(),
        :module_name => module_name,
        :module_branch_idh => branch_obj.id_handle(),
        :repo_url => RepoManager.repo_url(repo_name),
        :workspace_branch => branch_obj.get_field?(:branch),
        :branch_head_sha => RepoManager.branch_head_sha(branch_obj)
      }
      if version
        hash.merge!(:version => version)
        if assembly_name = version.respond_to?(:assembly_name) && version.assembly_name()
          hash.merge!(:assembly_name => assembly_name)
        end
      end
      replace(hash)
    end
  end

  class CloneUpdateInfo < ModuleRepoInfo
    def initialize(module_obj,version=nil)
      aug_branch = module_obj.get_augmented_workspace_branch(:filter => {:version => version})
      super(aug_branch[:repo],aug_branch[:module_name],module_obj.id_handle(),aug_branch,version)
      replace(Aux.hash_subset(self,[:repo_name,:repo_url,:module_name,:workspace_branch]))
      self[:commit_sha] = aug_branch[:current_sha]
    end
  end
end