dtk_require_common_lib('dsl')
module DTK
  class ServiceModule
    class DSLParser
      ExtMod = ::DtkCommon::DSL
      def self.implements_method?(method_name)
        if DirectoryParserMethods.include?(method_name)
          ExtMod::DirectoryParser::Git.implements_method?(method_name)
        elsif FileParserMethods.include?(method_name)
          ExtMod::FileParser.implements_method?(method_name)
        end
      end
      FileParserMethods = [:generate_hash]
      DirectoryParserMethods = [:parse_directory]

      def self.parse_directory(module_branch,file_type,opts={})
        repo_full_path,branch = RepoManager.repo_full_path_and_branch(module_branch)
        dir_parser = ExtMod::DirectoryParser::Git.new(:service_module,repo_full_path,branch)
        parsed_info = dir_parser.parse_directory(file_type,opts)

        return parsed_info if ParsingError.class_of?(parsed_info)

        file_type ? 
          Output.new(file_type,parsed_info) :
          parsed_info.inject(Hash.new){|h,(file_type,v)|h.merge(file_type => Output.new(file_type,v))} 
      end

      def self.generate_hash(file_type,output_array)
        ExtMod::FileParser.generate_hash(file_type,output_array)
      end

      def self.file_parser_output_array_class()
        ExtMod::FileParser::OutputArray
      end

      class Output < Array
        def initialize(file_type,object)
          super()
          @file_type = file_type
          if object.kind_of?(ExtMod::FileParser::OutputArray)
            object.each{|r|self << r}
          elsif object.kind_of?(Hash)
            #TODO: deprecate
            object.each_pair do |component_module,info|
              self << info.merge(:component_module => component_module)
            end
          else
            raise Error.new("Not implemented yet: Output parser for #{object.class}")
          end
        end
      end
    end
  end
end
