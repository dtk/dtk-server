module XYZ
  class ViewDefProcessor
    def self.save_view_in_cache?(type,id_handle,user,opts={})
      cmp_attrs_objs = get_model_info(id_handle,opts)
      view_def_key = cmp_attrs_objs[:view_def_key]
      return if SavedAlready[type][view_def_key]
      view_meta_hash = convert_to_view_def_form(type,cmp_attrs_objs)

      view_name = "#{type}.#{view_def_key}"
      view = R8Tpl::ViewR8.new(:component,view_name,user,true,view_meta_hash,{:view_type => type})
      #TODO: hack until have more geenral fn
      x=view.update_cache_for_virtual_object()
      SavedAlready[type][view_def_key] = TRUE
    end
   private 
    SavedAlready = {:edit => Hash.new, :display => Hash.new}
    def self.get_model_info(id_handle,opts={})
      id_handle.create_object().get_info_for_view_def()
    end

    def self.convert_to_view_def_form(type,cmp_attrs_objs)
      case type
        when :edit then convert_to_edit_view_def_form(cmp_attrs_objs)
        when :display then convert_to_display_view_def_form(cmp_attrs_objs)
        else Log.error("unsupported type #{type} was given")
      end
    end

    def self.convert_to_display_view_def_form(cmp_attrs_objs)
      ret = ActiveSupport::OrderedHash.new()
      ret[:action] = ""
      ret[:hidden_fields] = hidden_fields(:edit,cmp_attrs_objs)
      ret[:field_groups] = field_groups(cmp_attrs_objs[:attributes])
      ret
    end
    def self.convert_to_edit_view_def_form(cmp_attrs_objs)
      ret = ActiveSupport::OrderedHash.new()
      ret[:action] = ""
      ret[:hidden_fields] = hidden_fields(:edit,cmp_attrs_objs)
      ret[:field_groups] = field_groups(cmp_attrs_objs[:attributes])
      ret
    end

    def self.hidden_fields(type,cmp_attrs_objs)
      HiddenFields[type].map do |hf|
        {hf.keys.first => Aux::ordered_hash_subset(hf.values.first,[:required,:type,:value])}
      end
    end

    HiddenFields = {
      :list =>
      [
       {:id => {
            :required => true,
            :type => 'hidden',
         }}
      ],
      :edit => 
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
    }

    def self.field_list(attr_objs)
      #TODO stub
      attr_objs.map do |attr|
        {attr[:display_name].to_sym =>{
            :type => convert_type(attr[:data_type]),
            :help => '',
            :rows => 1,
            :cols => 40,
          }
        }
      end
    end

    def self.field_groups(attr_objs)
      [
       {
         :num_cols => 1,
         :display_labels => true,
         :fields => field_list(attr_objs)
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
