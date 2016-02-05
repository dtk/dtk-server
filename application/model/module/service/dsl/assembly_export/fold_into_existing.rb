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
module DTK; class ServiceModule
  class AssemblyExport
    module FoldIntoExisting
      r8_nested_require('fold_into_existing', 'assembly_section_proc')
      r8_nested_require('fold_into_existing', 'node_bindings_section_proc')

      # TODO: DTK-2208 Aldin: I changed logic here to use teh oreder of high level sections in ordered_hash_new_content
      #  to drive the high level order; then just for assembly section does it try to factor in comments, etc from existing assembly
      #  dsl
      def self.fold_into_existing_assembly_dsl(raw_content_existing, ordered_hash_new_content)
        ret = "---\n"
        assembly_section_proc = nil
        workflow_added = false
        ordered_hash_new_content.each_pair do |section_name, section_content_hash|
          section = { section_name => section_content_hash }
          text_section = 
            case section_name
             when :assembly
              assembly_section_proc ||= AssemblySectionProc.new(raw_content_existing)
              convert_to_text__assembly_section(assembly_section_proc, section)
             when :workflow, :workflows
              if workflow_added
                nil
              else
                workflow_added = true
                convert_to_text(section)
              end
             when :node_bindings
              node_bindings_section_proc ||= NodeBindingsSectionProc.new(raw_content_existing.split("\n"))
              convert_to_text__node_bindings_section(node_bindings_section_proc, section)
             when :description
              convert_to_text__description(raw_content_existing.split("\n"), section)
             else
              convert_to_text(section)
            end
          ret.concat(text_section) if text_section
        end
        ret
      end

      private
      
      def self.convert_to_text(section_content_hash)
        Aux.serialize(section_content_hash, :yaml).gsub("---\n", '')
      end
      
      def self.convert_to_text__assembly_section(assembly_section_proc, assembly_section_hash)
        processed_assembly_hash = assembly_section_proc.parse_and_order_assembly_hash(assembly_section_hash)
        prettify_assembly_string(convert_to_text(processed_assembly_hash))
      end

      def self.convert_to_text__node_bindings_section(node_bindings_section_proc, node_bindings_section_hash)
        processed_node_bindings_hash = node_bindings_section_proc.parse_and_order_node_bindings_hash(node_bindings_section_hash)
        prettify_assembly_string(convert_to_text(processed_node_bindings_hash))
      end

      def self.convert_to_text__description(raw_content_existing, new_description)
        raw_content_existing.each do |el|
          name = el.split(':').first
          return "#{el}\n" if name.eql?('description')
        end
        convert_to_text(new_description)
      end
      
      # add_empty_lines_and_comments
      def self.prettify_assembly_string(assembly_string)
        ret = ''
        
        assembly_string.each_line do |line|
          line.gsub!('assembly_wide/', '') if line.include?('assembly_wide/')
          str_line = line.strip.gsub('- ', '')
          
          if str_line.eql?("''")
            ret << "\n"
          elsif str_line.start_with?('!') && str_line.include?('#')
              ret << line.gsub(/- ! '(#.*)'/,  '\1')
          else
            ret << line
          end
        end
        
        ret
      end
      
    end
  end
end; end