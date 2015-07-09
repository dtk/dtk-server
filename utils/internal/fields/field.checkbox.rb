
class Fieldcheckbox < Fieldbase
  attr_accessor :default_class

  def initialize(field_meta)
    super(field_meta)
    @default_class = 'r8-checkbox'
    self.add_class(@default_class)
  end

  # This returns the Edit View of a input of type checkbox HTML form,
  # protected function
  def get_field_edit_html
    #    if(!@value.nil? && (@value == '1' || @value == 1)) then
    if (!@value.nil? && @value == true) then
      checked = 'checked="true"'
    else
      checked = ''
    end
    return '<input type="checkbox" id="' + @id + '" name="' + @name + '" value="1" class="' + @class_txt + '" ' + @checked + ' />'
  end

  # This returns the Edit View of a input of type text in Javascript form
  # protected function
  def get_field_edit_js
    # TODO: add JS rendering when generating JS fields class for client side rendering
    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit of a input for the checkbox in TPL/Smarty form
  # TODO: revisit and add leading hidden field for proper handling of unchecked form submissions
  # protected function
  def get_field_edit_rptl
    return '<input type="hidden" id="' + @id + '-hidden" name="' + @name + '" value="false" />
    <input type="checkbox" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="true" {%=' + @model_name + '[:' + @name + '_checked]%}" />
    '
  end

  # This returns the View of type view of a input for the checkbox in TPL/Smarty form
  # protected function
  # TODO: revisit and add leading hidden field for proper handling of unchecked form submissions
  def get_field_display_rtpl
    return '<input disabled="disabled" type="checkbox" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="true" {%=' + @model_name + '[:' + @name + '_checked]%}" />'
  end

  def get_field_display_html
    return '<HTML Display NOT IMPLEMENTED YET>'
  end

  # This returns the View of type list of a input for the checkbox in TPL/Smarty form
  # protected function
  def get_field_list_rtpl
    return '<input disabled="disabled" type="checkbox" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="1" checked="{%=' + @model_name + '[:' + @name + ']%}" />'
  end

  def get_field_list_html
    return '<HTML LIST NOT IMPLEMENTED YET>'
  end

  def get_field_list_js
    return '<JS LIST NOT IMPLEMENTED YET>'
  end
end
