#TBD: put under module and make as many as possible methods private
class FieldR8

  def initialize(r8view_ref=nil)
    @r8view_ref = r8view_ref
#TODO: enhance this once profiles are implemented
  end

  # This returns the contents for a provided field array and given view/render mode
  def getField(view_type, field_meta, renderMode='tpl')
    #convert any values that are symbols to strings
    field_meta.each do |key,value|
      if value.is_a?(Symbol) then field_meta[key] = value.to_s end
    end

    case(field_meta[:type])
      when "select","radio"
        field_meta[:options] = self.getFieldOptions(field_meta)
      when "multiselect"
        #if view of type edit add the []'s to allow for array to be returned in request for mult selects
        if(view_type == 'edit') then field_meta[:name] << '[]' end
        field_meta[:options] = self.getFieldOptions(field_meta)
#TODO: enhance this once profiles are implemented
          load_field_file "field.select.rb"
    end

#TODO: enhance this once profiles are implemented
    load_field_file "field.#{field_meta[:type]}.rb"
    fieldClass = 'Field' + field_meta[:type]
     #TBD: if wrapped in modeule M use form M.const_get
     fieldObj = Kernel.const_get(fieldClass).new(field_meta)
     fieldObj.set_includes(@r8view_ref)

    return fieldObj.render(view_type, renderMode)
  end

  # This adds the js exe call for the given field meta
  def addValidation(formId, field_meta)
    (field_meta['required'] == true) ? required = "true" : required = "false"

    case(field_meta['type'])
      when "radio"
        #classRefId used b/c styling cant be applied to radio itself so applied to reference div wrapper
        content = 'R8.forms.addValidator("' + formId + '",{"id":"' + field_meta[:id] + '","classRefId":"' + field_meta[:id] + '-radio-wrapper","type":"' + field_meta[:type] + '","required":' + required + '});'
      else
        content = 'R8.forms.addValidator("' + formId + '",{"id":"' + field_meta[:id] + '","type":"' + field_meta[:type] + '","required":' + required + '});'
    end
#    $GLOBALS['ctrl']->addJSExeScript(
#      array(
#        'content' => $content,
#        'race_priority' => 'low'
#      )
#    );
  end

#TODO: clean this up when option lists are fully implemented
  def getFieldOptions(field_meta)
    options = {
#      '' => '--None--',
      'One'=>'One',
      'Two'=>'Two',
      'Three'=>'Three',
      'Four'=>'Four',
    }
    return options
  end
 private
  def self.load_field_file(file_name)
    require UTILS_DIR + "/internal/fields/" + file_name
  end 
  def load_field_file(file_name)
    self.class.load_field_file(file_name)
  end 
  load_field_file("field.base.rb")
end


