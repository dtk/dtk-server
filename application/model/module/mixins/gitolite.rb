#
# All interaction that streamlines interaction with gitolite for modules should be inserted here. Main purpose is grouping
# logic for gitolite interaction in here.
#

module DTK
  module ModuleMixins
    module Gitolite
      def repo_file_content(module_branch, rel_file_path)
        repo_full_path, branch = RepoManager.repo_full_path_and_branch(module_branch)
        dir_parser = ::DtkCommon::DSL::DirectoryParser::Git.new(self.module_type(), repo_full_path, branch)
        file_content = dir_parser.file_content(rel_file_path)
      end
    end
  end
end