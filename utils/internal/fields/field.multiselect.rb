
class Fieldmultiselect < Fieldselect

  attr_accessor :default_class,:multiple

  def initialize(fieldMeta)
    super(fieldMeta)
    @defaultClass = 'r8-multiselect'
    @multiple = 'multiple="multiple"'
  end

  #this is overriden in order to set the multiselected which is needed
  #for correct compiling of the js template
  def setOptions(options)
    @option_str = ''
    options.each do |value,display|
      @option_str << '<option value="' + value + '" multiselected="{%=' + @obj_name + '[:' + @name + ']%}">' + display + '</option>'
    end
  end

  # This returns the View of type view for an input of type multiselect in TPL/Smarty form
  #protected function
  def getFieldDisplayTPL()
    fieldString = '{%=' + @obj_name + '[:' + @name + ']%}'
    return fieldString
  end

  # This returns the View of type list for an input of type multiselect in TPL/Smarty form
  #protected function
  def getFieldListTPL()
    fieldString = '{%=' + @obj_name + '[:' + @name + ']%}'
    return fieldString
  end

end