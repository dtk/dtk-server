
class Fieldhash < Fieldbase

  attr_accessor :default_class

  def initialize(field_meta)
    super(field_meta)

    @default_class = 'r8-hash'

    self.add_class(@default_class)
  end

  def get_field_edit_html()
    return '<HTML NOT IMPLEMENTED YET>'
  end

  def get_field_edit_js()
#TODO: add JS rendering when generating JS fields class for client side rendering
    return '<JS NOT IMPLEMENT YET>'
  end

  def get_field_edit_rtpl()
    rows = "6"
    cols = "30"
    return '<textarea id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" ' + rows +  ' ' + cols + '>' + @value + '</textarea>'
  end

  def get_field_display_rtpl()
    field_string = '{%=' + @model_name + '[:' + @name + '].inspect%}'
    return field_string
  end

  def get_field_list_rtpl()
    field_string = '{%=' + @model_name + '[:' + @name + '].inspect%}'
    return field_string
  end

end
