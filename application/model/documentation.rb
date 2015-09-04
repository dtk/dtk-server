require 'mustache'
require 'active_support/core_ext/object/instance_variables'



module DTK
  module Branch
    module DocumentationParsing

      TEMPLATE_EXTENSIONS = 'tpl|md'

      DOC_FOLDER = 'documentation' # final generated documentation folder
      DOC_EXTENSION = 'md'         # final generated documentation extension

      ##
      # Generate documentations based on template files in docs/ folder. After than perisist that generated documentation to git repo
      #
      def generate_and_persist_docs
        template_files = RepoManager.files(self).select { |f| f.match(/docs\/.*\.(#{TEMPLATE_EXTENSIONS})$/) }
        return if template_files.empty?

        dtk_model_data = retrive_model_data

        # we generate documentation and persist it to git repo
        begin
          template_files.each do |file_path|
            rendered_content = render(file_path, dtk_model_data)
            final_doc_path   = final_document_path(file_path)
            RepoManager.add_file_simplified(self, final_doc_path, rendered_content, "Adding generated document #{final_doc_path}")
          end
        rescue Mustache::Parser::SyntaxError => e
          raise ErrorUsage, "Unable to parse Mustache template, reasone: #{e.message}"
        end

        # finally we push these changes
        RepoManager.push_changes(self)
      end

    private

      def find_templates
        all_repo_files.select { |f| f.match(/.*\.(#{TEMPLATE_EXTENSIONS})$/) }
      end

      ##
      # Read 'dtk.model.yaml' into our domain model
      #
      def retrive_model_data
        file_content = RepoManager.get_file_content('dtk.model.yaml', self)
        content = YAML.load(file_content)
        Domain::Module.new(content.with_indifferent_access).instance_values
      end

      ###
      # Render and tidy up content, extra empty lines due to Mustache for loop behavior
      #
      def render(file_path, model_data)
        file_content = RepoManager.get_file_content(file_path, self)
        rendered_content = Mustache.render(file_content, model_data) || ''
        rendered_content.gsub(/\|(\r?\n)+\|/m, "|\n|")
      end

      ##
      # Changes file name and destination, from template to final document
      #
      def final_document_path(file_path)
        file_name = file_path.match(/([^\/]*)\..*$/)[1]         # extracts only name of the file, without extension
        File.join(DOC_FOLDER, "#{file_name}.#{DOC_EXTENSION}")
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
end