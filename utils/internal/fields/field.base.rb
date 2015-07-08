
# TODO: setup rdoc style
# This is the base field class that all form fields derive from
# <input>:   http://www.w3schools.com/tags/tag_input.asp
class Fieldbase
  attr_accessor :name,:id,:model_name,:value,:disabled,:classes,:field_meta,:render_mode

  def initialize(field_meta)
    @field_meta = field_meta

    @id = (@field_meta[:id].nil? == true ? '' : @field_meta[:id].to_s)
    @name = (@field_meta[:name].nil? == true ? '' : @field_meta[:name].to_s)
    @model_name = (@field_meta[:model_name].nil? == true ? '' : @field_meta[:model_name].to_s)

    @value = ''
    @disabled = (@field_meta[:read_only] || false)

    @classes = []           #array of CSS classes to add by default
    @class_txt = ''         #the string for the class="class_names" text

    @render_mode = 'rtpl'   #rtpl will render erubis style output, also 'html' available for raw html
    @r8_view_ref = nil       # pointer to calling view; used to pass back css includes
  end

  def set_includes(r8_view_ref)
    @r8_view_ref = r8_view_ref
  end

  #  The view mode represents how to render the field for a given user interaction
  #     -rtpl:   return field rendered in RTPL/Erubis format
  #     -js:  return field rendered in Javascript format
  #     -html:  return field rendered in raw HTML format
  def render(view_type, render_mode)
    self.set_class_txt

    if(render_mode != '') then @render_mode = render_mode end

    case view_type.downcase
      when "edit" then
        return self.get_field_edit
      when "display" then
        return self.get_field_display
      when "list" then
        return self.get_field_list
      when "search" then
        return (defined? self.get_field_search) ? self.get_field_search : self.get_field_edit
      # if getting to default then its calling a custom view
      else
        cstm_view_method = 'get_field_'+ view_type
        return self.send(cstm_view_method.to_sym)
    end
  end

  def get_field_edit
    case @render_mode
      when "html" then
        field_string = self.get_field_edit_html()
      when "js" then
        field_string = self.get_field_edit_js()
      #     when "rtpl" then
      else
        field_string = self.get_field_edit_rtpl()
    end
    return field_string
  end

  def get_field_display
    case @render_mode
      when "html" then
        field_string = self.get_field_display_html
      when "js" then
        field_string = self.get_field_display_js
      #      when "tpl" then
      else
        field_string = self.get_field_display_rtpl
    end
    return field_string
  end

  def get_field_list
    case @render_mode
      when "html" then
        field_string = self.get_field_list_html
      when "js" then
        field_string = self.get_field_list_js
      #      when "tpl" then
      else
        field_string = self.get_field_list_rtpl
    end
    return field_string
  end

  def add_class(class_to_add)
    @classes << class_to_add
  end

  def removeClass(class_to_remove)
    tmp_array = []

    @classes.each do |the_class|
      if(the_class != class_to_remove) then tmp_array << the_class end
    end
    @classes = tmp_array
  end

  def set_class_txt
    @class_txt = ''

    @classes.each do |the_class|
        @class_txt << the_class << " "
    end
    @class_txt.strip!
  end
end