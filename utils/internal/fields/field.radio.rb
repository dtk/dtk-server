
class Fieldradio < Fieldbase
  attr_accessor :default_class, :options, :option_str

  def initialize(field_meta)
    super(field_meta)

    @default_class = 'r8-radio'
    @options = []
    @option_str = ''

    self.add_class(@default_class)
    @options = field_meta[:options]
  end

  # This returns the Edit View of a radio HTML form element
  # protected function
  def get_field_edit_html
    return '<HTML NOT IMPLEMENTED YET>'
  end

  # This returns the Edit View of a input of type radio in Javascript form
  # protected function
  def get_field_edit_js
    # TODO: add JS rendering when generating JS fields class for client side rendering
    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit for an input of type radio in TPL/Smarty form
  # protected function
  def get_field_edit_rtpl
    radio_str = ''
    num_options = @options.length
    count = 0
    # add div wrapper for radio buttons, used on form validation
    radio_str << '<div id="' + @id + '-radio-wrapper">'
    @options.each do |key, value|
      count += 1
      radio_str << '<input type="radio" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="' + key + '" checked="{%=' + @model_name + '[:' + @name + ']%}" />' + value
      if (count < num_options) then radio_str << '<br/>' end
    end
    radio_str << '</div>'

    return radio_str
  end

  # This returns the View of type view for an input of type radio in TPL/Smarty form
  # protected function
  def get_field_display_rtpl
    field_string = '{%=' + @model_name + '[:' + @name + ']%}'
    return field_string
  end

  # This returns the View of type list for an input of type radio in TPL/Smarty form
  # protected function
  def get_field_list_rtpl
    field_string = '{%=' + @model_name + '[:' + @name + ']%}'
    return field_string
  end
end
