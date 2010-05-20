
class Fieldtext < Fieldbase

  attr_accessor :rows,:columns,:default_class,:read_only,:auto_expand,:drag_expand

  def initialize(fieldMeta)
    super(fieldMeta)

    @rows = 0
    @columns = 0
    @default_class = 'r8-text'
    @read_only = false
  
    #these control textarea inputs ability to auto resize or be draggable resize
    @auto_expand = false
    @drag_expand = false

    self.addClass(@default_class)

    if(!fieldMeta[:rows].nil?) then @rows = fieldMeta[:rows] end
    if(!fieldMeta[:cols].nil?) then @columns = fieldMeta[:cols] end
  end

  def getFieldEdit()
    #if rows not greater then 1 its a normal type="text", else its a textarea
    if(@rows <=1) then
      case(@render_mode)
        when "html"
          fieldString = self.getFieldEditTextHTML()
        when "js"
          fieldString = self.getFieldEditTextJS()
        when "tpl"
          fieldString = self.getFieldEditTextTPL()
        else
          fieldString = self.getFieldEditTextTPL()
      end
    else
      case(@render_mode)
        when "html"
          fieldString = self.getFieldEditTextAreaHTML()
        when "js"
          fieldString = self.getFieldEditTextAreaJS()
        when "tpl"
          fieldString = self.getFieldEditTextAreaTPL()
        else
          fieldString = self.getFieldEditTextAreaTPL()
      end
    end
    return fieldString
  end

  def getFieldDisplay()
    #if rows not greater then 1 its a normal type="text", else its a textarea
    if(@rows <=1) then
      case(@render_mode)
        when "html"
          fieldString = self.getFieldDisplayTextHTML()
        when "js"
          fieldString = self.getFieldDisplayTextJS()
        when "tpl"
          fieldString = self.getFieldDisplayTextTPL()
        else
          fieldString = self.getFieldDisplayTextTPL()
      end
    else
      case(@render_mode)
        when "html"
          fieldString = self.getFieldDisplayTextAreaHTML()
        when "js"
          fieldString = self.getFieldDisplayTextAreaJS()
        when "tpl"
          fieldString = self.getFieldDisplayTextAreaTPL()
        else
          fieldString = self.getFieldDisplayTextAreaTPL()
      end
    end
    return fieldString
  end

  def getFieldList()
    #if rows not greater then 1 its a normal type="text", else its a textarea
    if(@rows <=1) then
      case(@render_mode)
        when "html"
          fieldString = self.getFieldListTextHTML()
        when "js"
          fieldString = self.getFieldListTextJS()
        when "tpl"
          fieldString = self.getFieldListTextTPL()
        else
          fieldString = self.getFieldListTextTPL()
      end
    else
      case(@render_mode)
        when "html"
          fieldString = self.getFieldListTextAreaHTML()
        when "js"
          fieldString = self.getFieldListTextAreaJS()
        when "tpl"
          fieldString = self.getFieldListTextAreaTPL();
        else
          fieldString = self.getFieldListTextAreaTPL();
      end
    end
    return fieldString
  end

  # This returns the Edit View of a input of type text in HTML form
  #protected function
  def getFieldEditTextHTML()
    (@columns >=1) ? size = 'size="' + @columns.to_s + '"' : size = ''

    return '<input type="text" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="' + @value + '" ' + size + ' />'
  end

  # This returns the Edit View of a input of type text in Javascript form
  #protected function
  def getFieldEditTextJS()
#TODO: add JS rendering when generating JS fields class for client side rendering
    (@columns >=1) ? size = 'size="' + @columns.to_s + '"' : size = '' 

    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit for an field of type text in TPL/Smarty form
  #protected function
  def getFieldEditTextTPL()
    (@columns >=1) ? size = 'size="' + @columns.to_s + '"' : size = ''

    return '<input type="text" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="{%=' + @obj_name + '[:' + @name + ']%}" ' + size + ' />'
  end

  # This returns the View of a input of type text in TPL/Smarty form
  #protected function
  def getFieldDisplayTextTPL()
    return '{%=' + @obj_name + '[:' + @name + ']%}'
  end

  # This returns the View of type list for a field of type text in TPL/Smarty form
  #protected function
  def getFieldListTextTPL()
#        'objLink' => true,
#        'objLinkView' => 'view',

#TODO: revisit when implementing new request params, such as a=amp, app=amp, v=list (view=list)
#TODO: revisit to not hard code contact
    if(!@field_meta[:objLink].nil? && @field_meta[:objLink] == true) then
      return '<a href="javascript:R8.ctrl.request(\'obj=' + @obj_name + '&amp;action=' + @field_meta[:objLinkView] + '&amp;id={%=' + @obj_name + '[:id]%}\');">{%=' + obj_name + '[:' + @name + ']%}</a>'
#      return '<a href="javascript:R8.ctrl.request(\'list_by_guid={%=' + @obj_name + '[:id]%}\');">{%=' + obj_name + '[:' + @name + ']%}</a>'
    else
      return '{%=' + @obj_name + '[:' + @name + ']%}'
    end  
  end

  # This returns the Edit View of a input of type text in TPL/Smarty form
  #protected function
#TODO: revisit.., this isnt making sense right now.., revisit when working on getFieldEditTextJS
  def getFieldEditTextTPL_KEEP()
    (@columns >=1) ? size = 'size="' + @columns.to_s + '"' : size = ''

    return '<input type="text" id="{%=' + @obj_name + '[:id]%}" name="{%=' + @obj_name + '[:name]%}" class="{%=' + @obj_name + '[:class]%}" value="{%=' + @obj_name + '[:value]%}" size="{%=' + @obj_name + '[:size]%}" />'
  end

  # This returns the Edit View of a textarea in HTML form
  #protected function
  def getFieldEditTextAreaHTML()
    (@columns >=1) ? cols = ' cols="' + @columns.to_s + '"' : cols = ' '

    (@rows >=1) ? rows = ' rows="' + @rows.to_s + '"' : rows = ' rows="1"'

#TODO: re-examin how to set rows and cols, right now its coded into the element string and not in a smarty variable
#for run-time rendering
    return '<textarea id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" ' + rows +  ' ' + cols + '>' + @value + '</textarea>'
  end

  # This returns the Edit View of a textarea in Javascript form
  #protected function
  def getFieldEditTextAreaJS()
#TODO: add JS rendering when generating JS fields class for client side rendering
    (@columns >=1) ? cols = ' cols="' + @columns.to_s + '"' : cols = ''
    (@rows >=1) ? rows = 'rows="' + @rows.to_s + '"' : rows = ' rows="1"'

    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the Edit View of a textarea in TPL/Smarty form
  #protected function
  def getFieldEditTextAreaTPL()
    (@columns >=1) ? cols = ' cols="' + @columns.to_s + '"' : cols = ' '
    (@rows >=1) ? rows = ' rows="' + @rows.to_s + '"' : rows = ' rows="1"'
#TODO: re-examin how to set rows and cols, right now its coded into the element string and not in a smarty variable
#for run-time rendering
    return '<textarea id="' + @id + '" name="' + @name + '" class="'+ @class_txt + '" ' + rows + ' ' + cols + '>{%=' + @obj_name + '[:' + @name + ']%}</textarea>'
  end

  # This returns the View of a textarea in TPL/Smarty form
  #protected function
  def getFieldDisplayTextAreaTPL()
    (@columns >=1) ? cols = ' cols="' + @columns.to_s + '"' : cols = ' '
    (@rows >=1) ? rows = ' rows="' + @rows.to_s + '"' : rows = ' rows="1"'

#TODO: add nl2br if switching away from showing inside of a disabled textarea
    return '<textarea disabled="disabled" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" ' + rows + ' ' + cols + '>{%=' + @obj_name + '[:' + @name + ']%}</textarea>'
  end

  # This returns the View of a textarea in TPL/Smarty form
  #protected function
  def getFieldListTextAreaTPL()
    return '{%=obj[rowNum][:' + @name + ']%}'
  end

end
