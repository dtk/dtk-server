dtk_require_common_lib('dsl')
module DTK
  class ServiceModule
    class DirectoryParser
      DtkCommonDirectoryParser = ::DtkCommon::DSL::DirectoryParser::Git
      def self.implements_method?(method_name)
        DtkCommonDirectoryParser.implements_method?(method_name)
      end
      def self.parse_directory(module_branch,file_type=nil)
        repo_full_path,branch = RepoManager.repo_full_path_and_branch(module_branch)
        dir_parser = DtkCommonDirectoryParser.new(:service_module,repo_full_path,branch)
        dir_parser.parse_directory(file_type)
      end
    end
  end
end
