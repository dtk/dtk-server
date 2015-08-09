module DTK; class ServiceModule
  class AssemblyExport
    module FoldIntoExisting
      r8_nested_require('fold_into_existing', 'assembly_section_proc')

      def self.fold_into_existing_assembly_dsl(raw_content_existing, ordered_hash_new_content)
        ret = "---\n"
        assembly_section_proc = nil
        workflow_added = false
        ordered_hash_new_content.each_pair do |section_name, section_content_hash|
          text_section = 
            case section_name
             when :assembly
              assembly_section_proc ||= AssemblySectionProc.new(raw_content_existing.split("\n"))
              convert_to_text__assembly_section(assembly_section_proc, section_content_hash)
             when :workflow, :workflows
              unless workflow_added
                convert_to_text(section_name => section_content_hash)
                workflow_added = true
              end
             else
              convert_to_text(section_name => section_content_hash)
            end
          ret.concat(text_section)
        end
        ret
      end

      private
      
      def self.convert_to_text(section_content_hash)
        Aux.serialize(section_content_hash, :yaml).gsub("---\n", '')
      end
      
      def self.convert_to_text__assembly_section(assembly_section_proc, assembly_section_hash)
        processed_assembly_hash = assembly_section_proc.parse_and_order_components_hash(assembly_section_hash)
        prettify_assembly_string(convert_to_text(processed_assembly_hash))
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
