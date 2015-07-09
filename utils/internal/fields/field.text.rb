
class Fieldtext < Fieldbase
  attr_accessor :rows, :columns, :default_class, :read_only, :auto_expand, :drag_expand

  def initialize(field_meta)
    super(field_meta)

    @rows = 0
    @columns = 0
    @default_class = 'r8-text'
    @read_only = false

    # these control textarea inputs ability to auto resize or be draggable resize
    @auto_expand = false
    @drag_expand = false

    self.add_class(@default_class)

    if (!field_meta[:rows].nil?) then @rows = field_meta[:rows] end
    if (!field_meta[:cols].nil?) then @columns = field_meta[:cols] end
  end

  def get_field_edit
    # if rows not greater then 1 its a normal type="text", else its a textarea
    if (@rows <= 1) then
      case (@render_mode)
        when 'html'
          field_string = self.get_field_edit_text_html()
        when 'js'
          field_string = self.get_field_edit_text_js()
        when 'rtpl'
          field_string = self.get_field_edit_text_rtpl()
        else
          field_string = self.get_field_edit_text_rtpl()
      end
    else
      case (@render_mode)
        when 'html'
          field_string = self.get_field_edit_text_area_html()
        when 'js'
          field_string = self.get_field_edit_textarea_js()
        when 'rtpl'
          field_string = self.get_field_edit_textarea_rtpl()
        else
          field_string = self.get_field_edit_textarea_rtpl()
      end
    end
    return field_string
  end

  def get_field_display
    # if rows not greater then 1 its a normal type="text", else its a textarea
    if (@rows <= 1) then
      case (@render_mode)
        when 'html'
          field_string = self.get_field_display_text_html()
        when 'js'
          field_string = self.get_field_display_text_js()
        when 'rtpl'
          field_string = self.get_field_display_text_rtpl()
        else
          field_string = self.get_field_display_text_rtpl()
      end
    else
      case (@render_mode)
        when 'html'
          field_string = self.get_field_display_textarea_html()
        when 'js'
          field_string = self.get_field_display_textarea_js()
        when 'rtpl'
          field_string = self.get_field_display_textarea_rtpl()
        else
          field_string = self.get_field_display_textarea_rtpl()
      end
    end
    return field_string
  end

  def get_field_list
    # if rows not greater then 1 its a normal type="text", else its a textarea
    if (@rows <= 1) then
      case (@render_mode)
        when 'html'
          field_string = self.get_field_list_text_html()
        when 'js'
          field_string = self.get_field_list_text_js()
        when 'rtpl'
          field_string = self.get_field_list_text_rtpl()
        else
          field_string = self.get_field_list_text_rtpl()
      end
    else
      case (@render_mode)
        when 'html'
          field_string = self.get_field_list_textarea_html()
        when 'js'
          field_string = self.get_field_list_textarea_js()
        when 'rtpl'
          field_string = self.get_field_list_textarea_rtpl();
        else
          field_string = self.get_field_list_textarea_rtpl();
      end
    end
    return field_string
  end

  # This returns the Edit View of a input of type text in HTML form
  # protected function
  def get_field_edit_text_html
    (@columns >= 1) ? size = 'size="' + @columns.to_s + '"' : size = ''

    return '<input type="text" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="' + @value + '" ' + size + ' />'
  end

  # This returns the Edit View of a input of type text in Javascript form
  # protected function
  def get_field_edit_text_js
    # TODO: add JS rendering when generating JS fields class for client side rendering
    (@columns >= 1) ? size = 'size="' + @columns.to_s + '"' : size = ''

    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit for an field of type text in TPL/Smarty form
  # protected function
  def get_field_edit_text_rtpl
    (@columns >= 1) ? size = 'size="' + @columns.to_s + '"' : size = ''

    if @disabled == true then disabled = 'disabled="disabled"'
    else disabled = '' end
    name = @field_meta[:override_name] || @name
    return '<input type="text" ' + disabled + ' id="' + @id + '" name="' + name + '" class="' + @class_txt + '" value="{%=' + @model_name + '[:' + @name + ']%}" ' + size + ' />'
  end

  # This returns the View of a input of type text in TPL/Smarty form
  # protected function
  def get_field_display_text_rtpl
    return '{%=' + @model_name + '[:' + @name + ']%}'
  end

  # This returns the View of type list for a field of type text in TPL/Smarty form
  # protected function
  def get_field_list_text_rtpl
    #        'objLink' => true,
    #        'objLinkView' => 'view',

    # TODO: revisit when implementing new request params, such as a=amp, app=amp, v=list (view=list)
    # TODO: revisit to not hard code contact
    if (!@field_meta[:objLink].nil? && @field_meta[:objLink] == true) then
      return '<a href="/xyz/' + @model_name + '/display/' + '{%=' + @model_name + '[:id]%}">{%=' + model_name + '[:' + @name + ']%}</a>'
    #      return '<a href="javascript:R8.ctrl.request(\'obj=' + @model_name + '&amp;action=' + @field_meta[:objLinkView] + '&amp;id={%=' + @model_name + '[:id]%}\');">{%=' + model_name + '[:' + @name + ']%}</a>'
    #      return '<a href="javascript:R8.ctrl.request(\'list_by_guid={%=' + @model_name + '[:id]%}\');">{%=' + model_name + '[:' + @name + ']%}</a>'
    else
      return '{%=' + @model_name + '[:' + @name + ']%}'
    end
  end

  # This returns the Edit View of a input of type text in TPL/Smarty form
  # protected function
  # TODO: revisit.., this isnt making sense right now.., revisit when working on getFieldEditTextJS
  def getFieldEditTextTPL_KEEP
    (@columns >= 1) ? size = 'size="' + @columns.to_s + '"' : size = ''

    return '<input type="text" id="{%=' + @model_name + '[:id]%}" name="{%=' + @model_name + '[:name]%}" class="{%=' + @model_name + '[:class]%}" value="{%=' + @model_name + '[:value]%}" size="{%=' + @model_name + '[:size]%}" />'
  end

  # This returns the Edit View of a textarea in HTML form
  # protected function
  def get_field_edit_textarea_html
    (@columns >= 1) ? cols = ' cols="' + @columns.to_s + '"' : cols = ' '

    (@rows >= 1) ? rows = ' rows="' + @rows.to_s + '"' : rows = ' rows="1"'

    # TODO: re-examin how to set rows and cols, right now its coded into the element string and not in a smarty variable
    # for run-time rendering
    return '<textarea id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" ' + rows + ' ' + cols + '>' + @value + '</textarea>'
  end

  # This returns the Edit View of a textarea in Javascript form
  # protected function
  def get_field_edit_textarea_js
    # TODO: add JS rendering when generating JS fields class for client side rendering
    (@columns >= 1) ? cols = ' cols="' + @columns.to_s + '"' : cols = ''
    (@rows >= 1) ? rows = 'rows="' + @rows.to_s + '"' : rows = ' rows="1"'

    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the Edit View of a textarea in TPL/Smarty form
  # protected function
  def get_field_edit_textarea_rtpl
    (@columns >= 1) ? cols = ' cols="' + @columns.to_s + '"' : cols = ' '
    (@rows >= 1) ? rows = ' rows="' + @rows.to_s + '"' : rows = ' rows="1"'
    # TODO: re-examin how to set rows and cols, right now its coded into the element string and not in a smarty variable
    # for run-time rendering
    return '<textarea id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" ' + rows + ' ' + cols + '>{%=' + @model_name + '[:' + @name + ']%}</textarea>'
  end

  # This returns the View of a textarea in TPL/Smarty form
  # protected function
  def get_field_display_textarea_rtpl
    (@columns >= 1) ? cols = ' cols="' + @columns.to_s + '"' : cols = ' '
    (@rows >= 1) ? rows = ' rows="' + @rows.to_s + '"' : rows = ' rows="1"'

    # TODO: add nl2br if switching away from showing inside of a disabled textarea
    return '<textarea disabled="disabled" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" ' + rows + ' ' + cols + '>{%=' + @model_name + '[:' + @name + ']%}</textarea>'
  end

  # This returns the View of a textarea in TPL/Smarty form
  # protected function
  def get_field_list_textarea_rtpl
    return '{%=model[row_num][:' + @name + ']%}'
  end
end
