
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
# TODO: add JS rendering when generating JS fields class for client side rendering
    return '<JS NOT IMPLEMENT YET>'
  end

  def get_field_edit_rtpl()
    rows = 10
    cols = 50
    value = hash_to_string_fn() 
    name = @field_meta[:override_name]||@name
    field_string =  '<textarea id="' + @id + '" name="' + name + '" class="' + @class_txt + '" rows=' + rows.to_s +  ' cols=' + cols.to_s + '>' + value + '</textarea>'
    return field_string
  end

  def get_field_display_rtpl()
    return hash_to_string_fn()
  end

  def get_field_list_rtpl()
    return hash_to_string_fn()
  end
 private
  def hash_to_string_fn()
    "{%=lambda{|a|(a.kind_of?(String) ? a : JSON.pretty_generate(a)) if a}.call(#{@model_name}[:#{@name}])%}"
  end
end
