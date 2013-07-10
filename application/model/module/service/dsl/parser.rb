dtk_require_common_lib('dsl')
module DTK
  class ServiceModule
    class DSLParser
      DtkCommonDirectoryParser = ::DtkCommon::DSL::DirectoryParser::Git
      def self.implements_method?(method_name)
        ::DtkCommon::DSL::DirectoryParser::Git.implements_method?(method_name)
      end
      def self.parse_directory(module_branch,file_type=nil)
        repo_full_path,branch = RepoManager.repo_full_path_and_branch(module_branch)
        dir_parser = ::DtkCommon::DSL::DirectoryParser::Git.new(:service_module,repo_full_path,branch)
        parsed_info = dir_parser.parse_directory(file_type)
        file_type ? 
          Output.new(file_type,parsed_info) :
          parsed_info.inject(Hash.new){|h,(file_type,v)|h.merge(file_type => Output.new(file_type,v))} 
      end

      class Output < Array
        def initialize(file_type,object)
          super()
          @file_type = file_type
          if object.kind_of?(::DtkCommon::DSL::FileParser::OutputArray)
            object.each{|r|self << r}
          else
            raise Error.new("Not implemented yet: Output parser for #{object.class}")
          end
        end
      end
    end
  end
end
