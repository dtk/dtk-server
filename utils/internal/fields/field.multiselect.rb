
class Fieldmultiselect < Fieldselect
  attr_accessor :default_class,:multiple

  def initialize(field_meta)
    super(field_meta)
    @defaultClass = 'r8-multiselect'
    @multiple = 'multiple="multiple"'
  end

  # this is overriden in order to set the multiselected which is needed
  # for correct compiling of the js template
  def set_options(options)
    @option_str = ''
    options.each do |value,display|
      @option_str << '<option value="' + value + '" multiselected="{%=' + @model_name + '[:' + @name + ']%}">' + display + '</option>'
    end
  end

  # This returns the View of type view for an input of type multiselect in TPL/Smarty form
  # protected function
  def get_field_display_rtpl
    field_string = '{%=' + @model_name + '[:' + @name + ']%}'
    return field_string
  end

  # This returns the View of type list for an input of type multiselect in TPL/Smarty form
  # protected function
  def get_field_list_rtpl
    field_string = '{%=' + @model_name + '[:' + @name + ']%}'
    return field_string
  end
end