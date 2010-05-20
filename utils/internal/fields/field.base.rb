
=begin
TODO: setup rdoc style
This is the base field class that all form fields derive from
<input>:   http://www.w3schools.com/tags/tag_input.asp
=end
class Fieldbase

  attr_accessor :name,:id,:obj_name,:value,:disabled,:classes,:field_meta,:render_mode

  def initialize(fieldMeta) 
    @field_meta = fieldMeta

    @id = (@field_meta[:id].nil? == true ? '' : @field_meta[:id].to_s)
    @name = (@field_meta[:name].nil? == true ? '' : @field_meta[:name].to_s)
    @obj_name = (@field_meta[:objName].nil? == true ? '' : @field_meta[:objName].to_s)

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
  def render(viewType, renderMode)
    self.setClassTxt

    if(renderMode != '') then @render_mode = renderMode end

    case viewType.downcase
      when "edit" then
        return self.getFieldEdit
      when "display" then
        return self.getFieldDisplay
      when "list" then
        return self.getFieldList
      #if getting to default then its calling a custom view
      else
        cstmViewMethod = 'getField_'+ viewType
        return self.send(cstmViewMethod.to_sym)
    end
  end

  def getFieldEdit()
    case @render_mode
      when "html" then
        fieldString = self.getFieldEditHTML()
      when "js" then
        fieldString = self.getFieldEditJS()
#     when "tpl" then
      else
        fieldString = self.getFieldEditTPL()
    end
    return fieldString
  end

  def getFieldDisplay()
    case @render_mode
      when "html" then
        fieldString = self.getFieldDisplayHTML
      when "js" then
        fieldString = self.getFieldDisplayJS
#      when "tpl" then
      else
        fieldString = self.getFieldDisplayTPL
    end
    return fieldString
  end

  def getFieldList()
    case @render_mode
      when "html" then
        fieldString = self.getFieldListHTML
      when "js" then
        fieldString = self.getFieldListJS
#      when "tpl" then
      else
        fieldString = self.getFieldListTPL
    end
    return fieldString
  end

  def addClass(classToAdd)
    @classes << classToAdd
  end

  def removeClass(classToRemove)
    tmpArray = []

    @classes.each do |theclass|
      if(theclass != classToRemove) then tmpArray << theclass end
    end
    @classes = tmpArray
  end

  def setClassTxt()
    @class_txt = ''

    @classes.each do |theclass|
        @class_txt << theclass << " "
    end
    @class_txt.strip!
  end
end