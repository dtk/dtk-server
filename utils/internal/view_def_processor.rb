module XYZ
  class ViewDefProcessor
    # returns template path
    # TODO: hack now that needs saved_search prefix
    def self.save_view_in_cache?(type, id_handle, user, opts = {})
      # TODO: make more efficient be just getting view_def_key info first
      cmp_attrs_objs = get_model_info(id_handle, opts)
      view_def_key = cmp_attrs_objs[:view_def_key]
      view_name = "#{type}.#{view_def_key}"
      ret = "saved_search/#{view_name}"
      return ret if SavedAlready[type][view_def_key]
      view_meta_hash = convert_to_view_def_form(type, cmp_attrs_objs)

      view = R8Tpl::ViewR8.new(:component, view_name, user, true, view_meta_hash, view_type: type)
      view.update_cache_for_virtual_object()
      SavedAlready[type][view_def_key] = TRUE
      ret
    end

    private

    SavedAlready = { edit: {}, display: {} }
    def self.get_model_info(id_handle, _opts = {})
      id_handle.create_object().get_info_for_view_def()
    end

    def self.convert_to_view_def_form(type, cmp_attrs_objs)
      case type
        when :edit then convert_to_edit_view_def_form(cmp_attrs_objs)
        when :display then convert_to_display_view_def_form(cmp_attrs_objs)
        else Log.error("unsupported type #{type} was given")
      end
    end

    def self.convert_to_display_view_def_form(cmp_attrs_objs)
      ret = ActiveSupport::OrderedHash.new()
      ret[:action] = ''
      ret[:hidden_fields] = hidden_fields(:display, cmp_attrs_objs)
      ret[:field_groups] = field_groups(:display, cmp_attrs_objs[:attributes])
      ret
    end
    def self.convert_to_edit_view_def_form(cmp_attrs_objs)
      ret = ActiveSupport::OrderedHash.new()
      ret[:action] = ''
      ret[:hidden_fields] = hidden_fields(:edit, cmp_attrs_objs)
      ret[:field_groups] = field_groups(:edit, cmp_attrs_objs[:attributes])
      ret
    end

    def self.hidden_fields(type, _cmp_attrs_objs)
      HiddenFields[type].map do |hf|
        { hf.keys.first => Aux.ordered_hash_subset(hf.values.first, [:required, :type, :value]) }
      end
    end

    HiddenFields = {
      list:       [
       { id: {
            required: true,
            type: 'hidden'
         } }
      ],
      edit:       [
       {
         id: {
           required: true,
           type: 'hidden'
         }
       },
       {
         model: {
           required: true,
           type: 'hidden',
           value: 'component'
         }
       },
       {
         action: {
           required: true,
           type: 'hidden',
           value: 'save_attribute'
         }
        }
     ],
      display:       [
       {
         id: {
           required: true,
           type: 'hidden'
         }
       },
       {
         obj: {
           required: true,
           type: 'hidden',
           value: 'component'
         }
       },
       {
         action: {
           required: true,
           type: 'hidden',
           value: 'edit'
         }
        }
     ]
    }

    def self.field_list(type, attr_objs)
      case type
        when :edit then field_list_edit(attr_objs)
        when :display then field_list_display(attr_objs)
      end
    end
    def self.field_list_display(attr_objs)
      # TODO: stub
      attr_objs.map do |attr|
        { attr[:display_name].to_sym => {
            type: convert_type(attr[:data_type]),
            help: '',
            rows: 1,
            cols: 40
          }
        }
      end
    end
    def self.field_list_edit(attr_objs)
      # TODO: stub
      attr_objs.map do |attr|
        { attr[:display_name].to_sym => {
            type: convert_type(attr[:data_type]),
            help: '',
            rows: 1,
            cols: 40,
            id: "{%=component_id[:#{attr[:display_name]}]%}",
            override_name: "{%=component_id[:#{attr[:display_name]}]%}"
          }
        }
      end
    end

    def self.field_groups(type, attr_objs)
      [
       {
         num_cols: 1,
         display_labels: true,
         fields: field_list(type, attr_objs)
       }
      ]
    end

    def self.convert_type(data_type)
      TypeConvert[data_type] || 'text'
    end
    TypeConvert = {
      'string' => 'text',
      'json' => 'hash',
      'integer' => 'integer'
    }
  end
end
