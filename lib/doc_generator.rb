#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK
  class DocGenerator
    r8_nested_require('doc_generator', 'domain')

    def initialize(module_branch, parsed_dsl)
      @module_branch =  module_branch
      @parsed_dsl    = parsed_dsl

      # outputs after generate! called
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
    # opts can have key
    #  :raise_error_on_missing_var (Boolean)
    def generate!(opts = {})
      @file_path__content_array = []
      @file_paths = []

      doc_files = RepoManager.files(@module_branch).select { |f| SourceFile.match?(f) }
      return self if doc_files.empty?
  
      dsl_normalized_for_templates = Domain.normalize_top(@parsed_dsl)
pp [:dsl_normalized_for_templates, dsl_normalized_for_templates]      
      # we generate documentation and persist it to module
      @file_paths = []
      doc_files.each do |file_path|
        file_content = RepoManager.get_file_content(file_path, @module_branch)
        rendered_content = (SourceFile.match?(file_path, :template) ? render(file_content, file_path, dsl_normalized_for_templates, opts) : file_content)
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
    
    ###
    # Render using Mustache template
    #
    # opts can have key
    #  :raise_error_on_missing_var (Boolean)
    def render(file_content, file_path, model_data, opts)
      opts_render = { file_path: file_path, remove_empty_lines: true }.merge(opts)
      MustacheTemplate.render(file_content, model_data, opts_render)
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
end