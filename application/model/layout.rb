#TODO: unify with view_def_processor
module XYZ
  class Layout < Model
    def self.create_and_save_from_field_def(model_handle,field_def,view_type)
      layout_def = 
        case view_type
          when :edit then LayoutViewDefProcessor.layout_def_from_field_def__edit(field_def)
       end
      #TODO: stub
      {:groups => layout_def}
    end
   private
    module LayoutViewDefProcessor
      def self.layout_def_from_field_def__edit(field_def)
        indexed_groups = Hash.new
        field_def.each do |el|
          index = group_index(el)
          indexed_groups[index] ||= {
            #TODO: stub that name and i18n are teh same
            :name => group_name(el),
            :num_cols =>1,
            :i18n => group_name(el),
            :fields => Array.new
          }
          indexed_groups[index][:fields] << field_list__edit(el)
        end
        indexed_groups.values
      end
      
      def self.group_index(el)
        el[:component_id]
      end
      def self.group_name(el)
        if el[:node_name]
          "#{el[:node_name]}/#{el[:component_i18n]}"
        else
          el[:component_i18n]
        end
      end
      
      def self.field_list__edit(el)
        {el[:name].to_sym => {
            :type => convert_type(el[:type]),
            :help => el[:description] || '',
            :rows => 1,
            :cols => 40,
            :id => "{%=component_id[:#{el[:name]}]%}",
            :override_name => "{%=component_id[:#{el[:name]}]%}"
          }
        }
      end
      def self.convert_type(data_type)
        TypeConvert[data_type]||"text"
      end
      TypeConvert = {
        "string" => "text",
        "json" => "hash",
        "integer" => "integer"
      }
    end
  end
end
