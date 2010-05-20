require File.expand_path('field.text.rb', File.dirname(__FILE__))

class Fieldpercentage < Fieldtext

  def initialize(fieldMeta)
    super(fieldMeta)
  end

  # This returns the View of a input of type text in TPL/Smarty form
  #protected function
  def getFieldDisplayTextTPL()
    return '{%=' + @obj_name + '[:' + @name + ']%}%'
  end

  # This returns the View of type list for a field of type text in TPL/Smarty form
  #protected function
  def getFieldListTextTPL()
#        'objLink' => true,
#        'objLinkView' => 'view',

#TODO: revisit when implementing new request params, such as a=amp, app=amp, v=list (view=list)
#TODO: revisit to not hard code contact
    if(!@field_meta['objLink'].nil? && @field_meta['objLink'] == true) then
      return '<a href="javascript:R8.ctrl.request(\'obj=' + @obj_name + '&amp;action=' + @field_meta['objLinkView'] + '&amp;id={%=' + @obj_name + '[:id]%}\');">{%=' + @obj_name + '[:' + @name + ']%}%</a>'
    else
      return '{%=' + @obj_name + '[:' + @name + ']%}%'
    end
  end
end