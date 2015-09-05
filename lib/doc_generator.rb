require 'mustache'
require 'active_support/core_ext/object/instance_variables'

module DTK
  class DocGenerator
    def initialize(module_branch)
      @module_branch =  module_branch
      # outputs after geerate! called
      @file_path__content_array = nil
      @file_paths = nil
    end

    def file_path__content_array
      @file_path__content_array || fail(Error, "Method 'generate!' must first be called")
    end
    def file_paths
      @file_paths || fail(Error, "Method 'generate!' must first be called")
    end

    ##
    # Generate documentations based on template files in docs/ folder.
    #
    def generate!
      @file_path__content_array = []
      @file_paths = []

      doc_files = RepoManager.files(@module_branch).select { |f| SourceFile.match?(f) }
      return self if doc_files.empty?
  
      dtk_model_data = retrive_model_data
      
      # we generate documentation and persist it to module
      @file_paths = []
      doc_files.each do |file_path|
        file_content = RepoManager.get_file_content(file_path, @module_branch)
        rendered_content = (SourceFile.match?(file_path, :template) ? render(file_content, dtk_model_data) : file_content)
        final_doc_path   = final_document_path(file_path)
        @file_paths << final_doc_path
        @file_path__content_array << { path: final_doc_path, content: rendered_content }
      end
      self
    end

    private

    def final_document_path(source_file_path)
      TargetFile.target_path_from_source_path(source_file_path)
    end
    
    ##
    # Read 'dtk.model.yaml' into our domain model
    #
    def retrive_model_data
      file_content = RepoManager.get_file_content('dtk.model.yaml', @module_branch)
      content = YAML.load(file_content)
      Domain::Module.new(content.with_indifferent_access).instance_values
    end
    
    ###
    # Render and tidy up content, extra empty lines due to Mustache for loop behavior
    #
    def render(file_content, model_data)
      rendered_content = nil
      begin
        rendered_content = ::Mustache.render(file_content, model_data) || ''
      rescue ::Mustache::Parser::SyntaxError => e
        fail ErrorUsage, "Unable to parse Mustache template '#{file_path}':\n#{e.message}"
      end
      rendered_content.gsub(/\|(\r?\n)+\|/m, "|\n|")
    end
    
    module SourceFile
      BaseDir = 'docs'
      
      module Extension 
        Template = 'tpl'
        Markdown = 'md'
        All = [Template, Markdown]
        
        def self.extension(type)
          case type
          when :all      then "(#{All.join('|')})"
          when :template then Template
          when :markdown then Markdown
          else fail(Error, "Bad type '#{type}'")
          end
        end
      end
      
      def self.match(path, type = :all)
        ext = Extension.extension(type)
        regexp = /#{BaseDir}\/(.+)\.(#{ext})$/
        path.match(regexp)
      end
      def self.match?(path, type = :all)
        !!match(path, type)
      end
    end
    
    module TargetFile
      BaseDir    = 'documentation'
      Extension = 'md'
      
      ##
      # Changes file name and destination, from template to final document
      #
      def self.target_path_from_source_path(source_file_path)
        # removes doc sub folder and file extension
        extracted_file_path = SourceFile.match(source_file_path)[1]   
        File.join(BaseDir, "#{extracted_file_path}.#{Extension}")
      end
    end
  end
      
  ###
  # DTK Model (.yaml) is not in mustache-friendly format, so we transform it in domain class bellow
  #
    
  module Domain
    class Module
      attr_accessor :name, :dsl_version, :type, :components
      
      def initialize(data)
        @name = data[:module]
        @dsl_version = data[:dsl_version]
        @type = data[:module_type]
        @components = []
        (data[:components] || {}).each do |name, comp_data|
          @components << Domain::Component.new(name, comp_data).instance_values
        end
      end
    end
    
    class Component
      attr_accessor :name, :attributes, :external_ref
      
      def initialize(name, data_hash)
        @attributes = []
        @name = name
        @external_ref = data_hash[:external_ref]
        (data_hash[:attributes] || {}).each do |attr_name, comp_data|
          @attributes << Domain::Attribute.new(attr_name, comp_data).instance_values
        end
      end
    end
    
    class Attribute
      attr_accessor :name, :type, :required
      
      def initialize(name, data_hash)
        @name = name
        @type = data_hash[:type]
        @required = data_hash[:required]
      end
    end
  end
end

