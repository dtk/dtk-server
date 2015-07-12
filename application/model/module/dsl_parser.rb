module DTK
  class ModuleDSLParser
    ExtMod = ::DtkCommon::DSL
    FileParserMethods = [:generate_hash]
    DirectoryParserMethods = [:parse_directory]

    def self.parse_directory(module_branch, file_type, opts = {})
      repo_full_path, branch = RepoManager.repo_full_path_and_branch(module_branch)
      dir_parser = ExtMod::DirectoryParser::Git.new(module_type(), repo_full_path, branch)
      parsed_info = dir_parser.parse_directory(file_type, opts) || {}

      return parsed_info if module_class::ParsingError.is_error?(parsed_info)

      file_type ?
      Output.new(file_type, parsed_info) :
        parsed_info.inject({}) { |h, (file_type, v)| h.merge(file_type => Output.new(file_type, v)) }
    end

    def self.default_rel_path?(file_type)
      ExtMod::DirectoryParser::Git.default_rel_path?(module_type(), file_type)
    end

    def self.generate_hash(file_type, output_array)
      ExtMod::FileParser.generate_hash(file_type, output_array)
    end

    def self.file_parser_output_array_class
      ExtMod::FileParser::OutputArray
    end

    private

    def self.module_type
      fail Error.new('Abstract method that should not be called')
    end
    def self.module_class
      fail Error.new('Abstract method that should not be called')
    end

    class Output < Array
      def initialize(file_type, object)
        super()
        @file_type = file_type
        if object.is_a?(ExtMod::FileParser::OutputArray)
          object.each { |r| self << r }
        elsif object.is_a?(Hash)
          # TODO: deprecate
          object.each_pair do |component_module, info|
            self << info.merge(component_module: component_module)
          end
        else
          fail Error.new("Not implemented yet: Output parser for #{object.class}")
        end
      end
    end
  end
end
