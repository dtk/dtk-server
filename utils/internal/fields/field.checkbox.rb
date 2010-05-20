
class Fieldcheckbox < Fieldbase

  attr_accessor :default_class

  def initialize(fieldMeta)
    super(fieldMeta)
    @default_class = 'r8-checkbox'
    self.addClass(@default_class)
  end

   # This returns the Edit View of a input of type checkbox HTML form,
   #protected function
  def getFieldEditHTML()
    if(!@value.nil? && (@value == '1' || @value == 1)) then
      checked = 'checked="1"'
    else
      checked = ''
    end
    return '<input type="checkbox" id="'+ @id + '" name="' + @name + '" value="1" class="' + @class_txt + '" '+ @checked + ' />'
  end

   # This returns the Edit View of a input of type text in Javascript form
   #protected function
  def getFieldEditJS()
#TODO: add JS rendering when generating JS fields class for client side rendering
    return '<JS NOT IMPLEMENT YET>'
  end

   # This returns the View of type edit of a input for the checkbox in TPL/Smarty form
#TODO: revisit and add leading hidden field for proper handling of unchecked form submissions
   #protected function
  def getFieldEditTPL()
    return '<input type="hidden" id="' + @id + '-hidden" name="' + @name + '" value="0" />
    <input type="checkbox" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="1" checked="{%=' + @obj_name + '[:' + @name + ']%}" />
    '
  end

   # This returns the View of type view of a input for the checkbox in TPL/Smarty form
   #protected function
#TODO: revisit and add leading hidden field for proper handling of unchecked form submissions
  def getFieldDisplayTPL()
    return '<input disabled="disabled" type="checkbox" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="1" checked="{%=' + @obj_name + '[:' + @name + ']%}" />'
  end

  def getFieldDisplayHTML()
    return '<HTML Display NOT IMPLEMENTED YET>'
  end

   # This returns the View of type list of a input for the checkbox in TPL/Smarty form
   #protected function
  def getFieldListTPL()
    return '<input disabled="disabled" type="checkbox" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="1" checked="{%=' + @obj_name + '[:' + @name + ']%}" />'
  end

  def getFieldListHTML()
    return '<HTML LIST NOT IMPLEMENTED YET>'
  end

  def getFieldListJS()
    return '<JS LIST NOT IMPLEMENTED YET>'
  end

end