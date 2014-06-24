# TBD: put under module and make as many as possible methods private

module R8Tpl
class FieldR8
  include Utility::I18n

  def initialize(r8_view_ref=nil)
    @r8_view_ref = r8_view_ref
# TODO: enhance this once profiles are implemented
  end

  # This returns the contents for a provided field array and given view/render mode
  def get_field(view_type, field_meta, renderMode='rtpl')
    # convert any values that are symbols to strings
    field_meta.each do |key,value|
      if value.is_a?(Symbol) then field_meta[key] = value.to_s end
    end

    case(field_meta[:type])
      when "select","radio"
        field_meta[:options] = self.get_field_options(field_meta)
      when "multiselect"
        # if view of type edit add the []'s to allow for array to be returned in request for mult selects
        field_meta[:options] = self.get_field_options(field_meta)
        if(view_type == 'edit' || view_type == 'search') then field_meta[:name] << '[]' end
# TODO: enhance this once profiles are implemented
        load_field_file "field.select.rb"
    end

# TODO: enhance this once profiles are implemented
    load_field_file "field.#{field_meta[:type]}.rb"
    fieldClass = 'Field' + field_meta[:type]
# TBD: if wrapped in modeule M use form M.const_get
    field_obj = Kernel.const_get(fieldClass).new(field_meta)
    field_obj.set_includes(@r8_view_ref)

    return field_obj.render(view_type, renderMode)
  end

  # This adds the js exe call for the given field meta
  def add_validation(formId, field_meta)
    (field_meta[:required] == true) ? required = "true" : required = "false"

    case(field_meta[:type])
      when "radio","select"
        # classRefId used b/c styling cant be applied to radio itself so applied to reference div wrapper
#        content = 'R8.forms.addValidator("' + formId + '",{"id":"' + field_meta[:id] + '","classRefId":"' + field_meta[:id] + '-radio-wrapper","type":"' + field_meta[:type] + '","required":' + required + '});'
      else
#        content = 'R8.forms.addValidator("' + formId + '",{"id":"' + field_meta[:id] + '","type":"' + field_meta[:type] + '","required":' + required + '});'
    end
#    $GLOBALS['ctrl']->addJSExeScript(
#      array(
#        'content' => $content,
#        'race_priority' => 'low'
#      )
#    );
  end

# TODO: clean this up when option lists are fully implemented
  def get_field_options(field_meta)
    options_lists = get_model_options(field_meta[:model_name])
# TODO: decide if list should just be key'd off of name, or a :options value?
    options = options_lists[field_meta[:name].to_sym]

=begin
    options = {
#      '' => '--None--',
      'inactive' => 'One',
      'warning' => 'Two',
      'error' => 'Three',
      'good' => 'Four',
    }
=end
    return options
  end
 private
  def self.load_field_file(file_name)
    r8_require("#{UTILS_DIR}/fields/#{file_name}")
  end 
  def load_field_file(file_name)
    self.class.load_field_file(file_name)
  end 
  load_field_file("field.base.rb")
end

end
