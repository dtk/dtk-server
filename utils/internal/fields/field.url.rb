
require File.expand_path('field.text.rb', File.dirname(__FILE__))

class Fieldurl < Fieldtext

  def initialize(field_meta)
    super(field_meta)
  end

  # This returns the View of a input of type text in TPL/Smarty form
  #protected function
  def getFieldDisplayTextTPL()
    (!@field_meta[:target].nil? && @field_meta[:target] !='') ? target = 'target="' + @field_meta[:target] + '"' : target = ''

    return '<a href="{%=' + @model_name + '[:' + @name + ']%}" ' + target + '>{%=' + @model_name + '[:' + @name + ']%}</a>'
  end

  def getFieldListTextTPL()
    (!@field_meta[:target].nil? && @field_meta[:target] !='') ? target = 'target="' + @field_meta[:target] + '"' : target = ''

    return '<a href="{%=' + @model_name + '[:' + @name + ']%}" ' + target + '>{%=' + @model_name + '[:' + @name + ']%}</a>'
  end

end
