
class Fieldemail < Fieldbase

  attr_accessor :columns,:default_class,:readonly

  def initialize(fieldMeta)
    super(fieldMeta)

    @columns = 0
#TODO: move this to a CSS config file so it can be changes easier
    @default_class = 'r8-email'
    @readonly = false
    self.addClass(@default_class)
    (!fieldMeta['cols'].nil?) ? @columns = fieldMeta['cols'] : @columns = 40
  end

  # This returns the Edit View of a input of type text in HTML form
  #protected function
  def getFieldEditHTML()
    if(@columns >=1) 
    then @size = 'size="' + @columns.to_s + '"'
    else @size = ''
    end

    return '<input type="text" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="' + @value + '" ' + @size + ' />'
  end

  # This returns the Edit View of a input of type text in Javascript form
  #protected function
  def getFieldEditJS()
#TODO: add JS rendering when generating JS fields class for client side rendering
    if(@columns >=1) 
    then @size = 'size="' + @columns.to_s + '"'
    else @size = ''
    end
    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit for an input of type email in TPL/Smarty form
  #protected function
  def getFieldEditTPL()
    if(@columns >=1) 
    then @size = 'size="' + @columns.to_s + '"'
    else @size = ''
    end
    return '<input type="text" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="{%=' + @obj_name + '[:' + @name + ']%}" ' + @size + ' />'
  end

  # This returns the View of type view for an input of type email in TPL/Smarty form
  #protected function
  def getFieldDisplayTPL()
    return '<a href="mailto:{%=' + @obj_name + '[:' + @name + ']%}">{%=' + @obj_name + '[:' + @name + ']%}</a>'
  end

  # This returns the View of type list for an input of type email in TPL/Smarty form
  #protected function
  def getFieldListTPL()
    return '<a href="mailto:{%=' + @obj_name + '[:' + @name + ']%}">{%=' + @obj_name + '[:'+ @name + ']%}</a>'
  end

end
