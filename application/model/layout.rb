# TODO: unify with view_def_processor
module XYZ
  class Layout < Model

    def self.save(parent_id_handle,layout_info)
      name = "foo" #TODO: stub
      hash = {
        :display_name => name
      }.merge(layout_info)
      create_hash = {:layout => {name => hash}}

      new_id = create_from_hash(parent_id_handle,create_hash).map{|x|x[:id]}.first
      new_id
    end

    def self.create_and_save_from_field_def(parent_id_handle,field_def,view_type)
      layout_def = create_def_from_field_def(field_def,view_type)
      layout_info = {
        :def => layout_def,
        :type => view_type.to_s
      }
      save(parent_id_handle,layout_info)
    end

    def self.create_def_from_field_def(field_def,view_type)
=begin
        case view_type.to_s
         when "wspace-edit" then LayoutViewDefProcessor.layout_groups_from_field_def__edit(field_def)
         else raise Error.new("type #{view_type} is unexpected")
       end
=end
      groups = LayoutViewDefProcessor.layout_groups_from_field_def__edit(field_def)
      {:groups => groups}
    end
   private
    module LayoutViewDefProcessor
      def self.layout_groups_from_field_def__edit(field_def)
        indexed_groups = Hash.new
        field_def.each do |el|
          index = group_index(el)
          indexed_groups[index] ||= {
            :name => group_name(el),
            :num_cols =>1,
            :i18n => group_i18n(el),
            :fields => Array.new
          }
          indexed_groups[index][:fields] << field_list__edit(el)
        end
        indexed_groups.values
      end
      
      def self.group_index(el)
        el[:component_id]
      end
      def self.group_i18n(el)
        if el[:node_name]
          "#{el[:node_name]}/#{el[:component_i18n]}"
        else
          el[:component_i18n]
        end
      end

      def self.group_name(el)
        group_i18n(el).gsub(/[^A-Za-z0-9_]/,"_")
      end
      
      def self.field_list__edit(el)
        {:name => el[:name],
          :type => convert_type(el[:type]),
          :help => el[:description] || '',
          :rows => 1,
          :cols => 40,
          :id => "{%=component_id[:#{el[:name]}]%}",
          :override_name => "{%=component_id[:#{el[:name]}]%}"
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
