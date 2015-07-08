
class Fieldselect < Fieldbase
  attr_accessor :default_class,:option_str

  def initialize(field_meta)
    super(field_meta)

    @default_class = 'r8-select'
    @option_str = ''

    self.add_class(@default_class)
    self.set_options(field_meta[:options])
  end

  def set_options(options)
    @option_str = ''
    options.each do |value,display|
      #      @option_str << '<option value="' + value + '" selected="{%=' + @model_name + '[:' + @name + ']%}">' + display + '</option>'
      @option_str << '<option value="' + value + '" {%=' + @model_name + '[:' + @name + '_options_list][:'+value+'_selected]%}">' + display + '</option>'
    end
  end

  # This returns the Edit View of a select HTML form element
  # protected function
  def get_field_edit_html
    return '<HTML NOT IMPLEMENTED YET>'
  end

  # This returns the Edit View of a input of type select in Javascript form
  # protected function
  def get_field_edit_js
    # TODO: add JS rendering when generating JS fields class for client side rendering
    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit for an input of type select in rtpl form
  # protected function
  def get_field_edit_rtpl
    (!@multiple.nil? && @multiple != '') ? multiple = @multiple : multiple = ''

    select_str = '<select id="' + @id + '" name="' + @name + '" '+ multiple + '>'
    select_str << @option_str
    select_str << '</select>'

    return select_str
  end

  # This returns the View of type view for an input of type select in TPL/Smarty form
  # protected function
  def get_field_display_rtpl
    # TODO: revisit when implementing save/display of multiselct values
    #    if(isset($this->multiple) && $this->multiple != '')
    #      $multiple = $this->multiple;
    #    else $multiple = '';

    field_string = '{%=' + @model_name + '[:' + @name + '_display]%}'
    return field_string
  end

  # This returns the View of type list for an input of type select in TPL/Smarty form
  # protected function
  def get_field_list_rtpl
    # TODO: revisit when implementing save/display of multiselct values
    #    if(!@multiple.nil? && @multiple != '') then
    #      multiple = @multiple
    #    else multiple = ''
    #    end

    field_string = '{%=' + @model_name + '[:' + @name + '_display]%}'
    #    field_string = '{%=_'+@model_name+'[:options_list]['+@model_name+'[:'+@name+']]%}'
    return field_string
  end
end