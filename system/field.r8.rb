#TBD: put under module and make as many as possible methods private
class FieldR8

  def initialize(r8view_ref=nil)
    @r8view_ref = r8view_ref
#TODO: enhance this once profiles are implemented
  end

  # This returns the contents for a provided field array and given view/render mode
  def getField(viewType, fieldMeta, renderMode='tpl')
    #convert any values that are symbols to strings
    fieldMeta.each do |key,value|
      if value.is_a?(Symbol) then fieldMeta[key] = value.to_s end
    end

    case(fieldMeta[:type])
      when "select","radio"
        fieldMeta[:options] = self.getFieldOptions(fieldMeta)
      when "multiselect"
        #if view of type edit add the []'s to allow for array to be returned in request for mult selects
        if(viewType == 'edit') then fieldMeta[:name] << '[]' end
        fieldMeta[:options] = self.getFieldOptions(fieldMeta)
#TODO: enhance this once profiles are implemented
          load_field_file "field.select.rb"
    end

#TODO: enhance this once profiles are implemented
    load_field_file "field.#{fieldMeta[:type]}.rb"
    fieldClass = 'Field' + fieldMeta[:type]
     #TBD: if wrapped in modeule M use form M.const_get
     fieldObj = Kernel.const_get(fieldClass).new(fieldMeta)
     fieldObj.set_includes(@r8view_ref)

    return fieldObj.render(viewType, renderMode)
  end

  # This adds the js exe call for the given field meta
  def addValidation(formId, fieldMeta)
    (fieldMeta['required'] == true) ? required = "true" : required = "false"

    case(fieldMeta['type'])
      when "radio"
        #classRefId used b/c styling cant be applied to radio itself so applied to reference div wrapper
        content = 'R8.forms.addValidator("' + formId + '",{"id":"' + fieldMeta[:id] + '","classRefId":"' + fieldMeta[:id] + '-radio-wrapper","type":"' + fieldMeta[:type] + '","required":' + required + '});'
      else
        content = 'R8.forms.addValidator("' + formId + '",{"id":"' + fieldMeta[:id] + '","type":"' + fieldMeta[:type] + '","required":' + required + '});'
    end
#    $GLOBALS['ctrl']->addJSExeScript(
#      array(
#        'content' => $content,
#        'race_priority' => 'low'
#      )
#    );
  end

#TODO: clean this up when option lists are fully implemented
  def getFieldOptions(fieldMeta)
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
    require UTILS_DIR + "internal/fields/" + file_name
  end 
  def load_field_file(file_name)
    self.class.load_field_file(file_name)
  end 
  load_field_file("field.base.rb")
end


