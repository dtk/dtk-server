
class Fieldradio < Fieldbase

  attr_accessor :default_class,:options,:option_str

  def initialize(fieldMeta)
    super(fieldMeta)

    @default_class = 'r8-radio'
    @options = []
    @option_str = ''

    self.addClass(@default_class)
    @options = fieldMeta[:options]
  end

  # This returns the Edit View of a radio HTML form element
  #protected function
  def getFieldEditHTML()
    return '<HTML NOT IMPLEMENTED YET>'
  end

  # This returns the Edit View of a input of type radio in Javascript form
  #protected function
  def getFieldEditJS()
#TODO: add JS rendering when generating JS fields class for client side rendering
    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit for an input of type radio in TPL/Smarty form
  #protected function
  def getFieldEditTPL()
    radioStr = ''
    numOptions = @options.length
    count = 0
    #add div wrapper for radio buttons, used on form validation
    radioStr << '<div id="' + @id + '-radio-wrapper">'
    @options.each do |key,value|
      count +=1
      radioStr << '<input type="radio" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="' + key + '" checked="{%=' + @obj_name + '[:' + @name + ']%}" />' + value
      if(count < numOptions) then radioStr << '<br/>' end
    end
    radioStr << '</div>'

    return radioStr
  end

  # This returns the View of type view for an input of type radio in TPL/Smarty form
  #protected function
  def getFieldDisplayTPL()
    fieldString = '{%=' + @obj_name + '[:' + @name + ']%}'
    return fieldString
  end

  # This returns the View of type list for an input of type radio in TPL/Smarty form
  #protected function
  def getFieldListTPL()
    fieldString = '{%=' + obj_name + '[:' + @name + ']%}'
    return fieldString
  end

end