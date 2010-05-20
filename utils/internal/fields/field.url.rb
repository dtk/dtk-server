
require File.expand_path('field.text.rb', File.dirname(__FILE__))

class Fieldurl < Fieldtext

  def initialize(fieldMeta)
    super(fieldMeta)
  end

  # This returns the View of a input of type text in TPL/Smarty form
  #protected function
  def getFieldDisplayTextTPL()
    (!@field_meta[:target].nil? && @field_meta[:target] !='') ? target = 'target="' + @field_meta[:target] + '"' : target = ''

    return '<a href="{%=' + @obj_name + '[:' + @name + ']%}" ' + target + '>{%=' + @obj_name + '[:' + @name + ']%}</a>'
  end

  def getFieldListTextTPL()
    (!@field_meta[:target].nil? && @field_meta[:target] !='') ? target = 'target="' + @field_meta[:target] + '"' : target = ''

    return '<a href="{%=' + @obj_name + '[:' + @name + ']%}" ' + target + '>{%=' + @obj_name + '[:' + @name + ']%}</a>'
  end

end
