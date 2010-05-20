
class Fieldselect < Fieldbase

  attr_accessor :default_class,:option_str

  def initialize(fieldMeta)
    super(fieldMeta)

    @default_class = 'r8-select'
    @option_str = ''

    self.addClass(@default_class)
    self.setOptions(fieldMeta[:options])
  end

  def setOptions(options)
    @option_str = ''
    options.each do |value,display|
      @option_str << '<option value="' + value + '" selected="{%=' + @obj_name + '[:' + @name + ']%}">' + display + '</option>'
    end
  end

  # This returns the Edit View of a select HTML form element
  #protected function
  def getFieldEditHTML()
    return '<HTML NOT IMPLEMENTED YET>'
  end

  # This returns the Edit View of a input of type select in Javascript form
  #protected function
  def getFieldEditJS()
#TODO: add JS rendering when generating JS fields class for client side rendering
    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit for an input of type select in TPL/Smarty form
  #protected function
  def getFieldEditTPL()
    (!@multiple.nil? && @multiple != '') ? multiple = @multiple : multiple = ''

    selectStr = '<select id="' + @id + '" name="' + @name + '" '+ multiple + '>'
    selectStr << @option_str
    selectStr << '</select>'

    return selectStr
  end

  # This returns the View of type view for an input of type select in TPL/Smarty form
  #protected function
  def getFieldDisplayTPL()
#TODO: revisit when implementing save/display of multiselct values
#    if(isset($this->multiple) && $this->multiple != '')
#      $multiple = $this->multiple;
#    else $multiple = '';

    fieldString = '{%=' + @obj_name + '[:' + @name + ']%}'
    return fieldString
  end

  # This returns the View of type list for an input of type select in TPL/Smarty form
  #protected function
  def getFieldListTPL()
#TODO: revisit when implementing save/display of multiselct values
#    if(!@multiple.nil? && @multiple != '') then
#      multiple = @multiple
#    else multiple = ''
#    end

    fieldString = '{%=' + @obj_name + '[:' + @name + ']%}'
    return fieldString
  end
end