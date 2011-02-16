module XYZ
  class ViewDefProcessor
    def self.get(id_handle,opts={})
      cmp_attrs_objs = id_handle.create_object().get_info_for_view_def()
pp [:cmp_attrs_objs,cmp_attrs_objs]
      convert_to_view_def_form(cmp_attrs_objs)
    end
    private 
    def self.convert_to_view_def_form(cmp_attrs_objs)
      ret = ActiveSupport::OrderedHash.new()
      ret[:action] = ""
      ret[:hidden_fields] = hidden_fields(cmp_attrs_objs)
      ret[:field_groups] = field_groups(cmp_attrs_objs[:attributes])
      ret
    end
    def self.hidden_fields(cmp_attrs_objs)
      HiddenFields.map do |hf|
        {hf.keys.first => Aux::ordered_hash_subset(hf.values.first,[:required,:type,:value])}
      end
    end

    HiddenFields = 
      [
       {
         :id => {
           :required => true,
           :type => 'hidden',
         }
       },
       {
         :model => {
           :required => true,
           :type => 'hidden',
           :value => 'virtual_object',
         }
       },
       {
         :action => {
           :required => true,
           :type => 'hidden',
           :value => 'save',
         },
        }
     ]

    def self.field_groups(attr_objs)
      fields = attr_objs.map do |attr|
        #stub
        {attr[:display_name].to_sym =>{
            :type => convert_type(attr[:data_type]),
            :help => '',
            :rows => 1,
            :cols => 40,
          }
        }
      end

      [
       {
         :num_cols => 1,
         :display_labels => true,
         :fields => fields
       }]
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
