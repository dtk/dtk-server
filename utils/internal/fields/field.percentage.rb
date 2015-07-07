require File.expand_path('field.text.rb', File.dirname(__FILE__))

class Fieldpercentage < Fieldtext
  def initialize(field_meta)
    super(field_meta)
  end

  # This returns the View of a input of type text in TPL/Smarty form
  # protected function
  def get_field_display_text_rtpl
    return '{%=' + @model_name + '[:' + @name + ']%}%'
  end

  # This returns the View of type list for a field of type text in TPL/Smarty form
  # protected function
  def get_field_list_text_rtpl
    #        'objLink' => true,
    #        'objLinkView' => 'view',

    # TODO: revisit when implementing new request params, such as a=amp, app=amp, v=list (view=list)
    # TODO: revisit to not hard code contact
    # TODO: replace objLink with model_link
    if(!@field_meta['objLink'].nil? && @field_meta['objLink'] == true) then
      return '<a href="javascript:R8.ctrl.request(\'obj=' + @model_name + '&amp;action=' + @field_meta['objLinkView'] + '&amp;id={%=' + @model_name + '[:id]%}\');">{%=' + @model_name + '[:' + @name + ']%}%</a>'
    else
      return '{%=' + @model_name + '[:' + @name + ']%}%'
    end
  end
end