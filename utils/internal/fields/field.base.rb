
=begin
TODO: setup rdoc style
This is the base field class that all form fields derive from
<input>:   http://www.w3schools.com/tags/tag_input.asp
=end
class Fieldbase

  attr_accessor :name,:id,:model_name,:value,:disabled,:classes,:field_meta,:render_mode

  def initialize(field_meta) 
    @field_meta = field_meta

    @id = (@field_meta[:id].nil? == true ? '' : @field_meta[:id].to_s)
    @name = (@field_meta[:name].nil? == true ? '' : @field_meta[:name].to_s)
    @model_name = (@field_meta[:model_name].nil? == true ? '' : @field_meta[:model_name].to_s)

    @value = ''
    @disabled = false
  
    @classes = []           #array of CSS classes to add by default
    @class_txt = ''         #the string for the class="classNames" text
  
    @render_mode = 'tpl'     #tpl will render smarty style output, also 'html' available for raw html
    @r8view_ref = nil # pointer to calling view; used to pass back css includes
  end
  def set_includes(r8view_ref)
    @r8view_ref = r8view_ref
  end
  
  #  The view mode represents how to render the field for a given user interaction
  #     -tpl:   return field rendered in TPL/Smarty format
  #     -js:  return field rendered in Javascript format
  #     -html:  return field rendered in raw HTML format
  def render(view_type, render_mode)
    self.setClassTxt

    if(render_mode != '') then @render_mode = render_mode end

    case view_type.downcase
      when "edit" then
        return self.getFieldEdit
      when "display" then
        return self.getFieldDisplay
      when "list" then
        return self.getFieldList
      #if getting to default then its calling a custom view
      else
        cstm_view_method = 'getField_'+ view_type
        return self.send(cstm_view_method.to_sym)
    end
  end

  def getFieldEdit()
    case @render_mode
      when "html" then
        field_string = self.getFieldEditHTML()
      when "js" then
        field_string = self.getFieldEditJS()
#     when "tpl" then
      else
        field_string = self.getFieldEditTPL()
    end
    return field_string
  end

  def getFieldDisplay()
    case @render_mode
      when "html" then
        field_string = self.getFieldDisplayHTML
      when "js" then
        field_string = self.getFieldDisplayJS
#      when "tpl" then
      else
        field_string = self.getFieldDisplayTPL
    end
    return field_string
  end

  def getFieldList()
    case @render_mode
      when "html" then
        field_string = self.getFieldListHTML
      when "js" then
        field_string = self.getFieldListJS
#      when "tpl" then
      else
        field_string = self.getFieldListTPL
    end
    return field_string
  end

  def addClass(class_to_add)
    @classes << class_to_add
  end

  def removeClass(class_to_remove)
    tmp_array = []

    @classes.each do |the_class|
      if(the_class != class_to_remove) then tmp_array << the_class end
    end
    @classes = tmp_array
  end

  def setClassTxt()
    @class_txt = ''

    @classes.each do |the_class|
        @class_txt << the_class << " "
    end
    @class_txt.strip!
  end
end