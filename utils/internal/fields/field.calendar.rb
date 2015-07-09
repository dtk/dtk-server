

class Fieldcalendar < Fieldbase
  attr_accessor :default_class, :read_only, :cal_type

  def initialize(field_meta)
    super(field_meta)
    @default_class = 'r8-cal'
    self.add_class(@default_class)
    @read_only = false

    (!field_meta['cols'].nil?) ? @columns = field_meta['cols'] : @columns = 40
    (!field_meta['cal_type'].nil?) ? @cal_type = field_meta['cal_type'] : @cal_type = 'basic'
  end

  def set_includes(r8_view_ref)
    super(r8_view_ref)
    r8_view_ref.add_to_js_require('http://yui.yahooapis.com/2.7.0/build/element/element.js')
    r8_view_ref.add_to_js_require('http://yui.yahooapis.com/2.7.0/build/button/button.js')
    r8_view_ref.add_to_js_require('http://yui.yahooapis.com/2.7.0/build/calendar/calendar.js')
    r8_view_ref.add_to_js_require('http://yui.yahooapis.com/2.7.0/build/container/container.js')

    r8_view_ref.add_to_css_require('http://yui.yahooapis.com/2.7.0/build/container/assets/skins/sam/container.css');
     r8_view_ref.add_to_css_require('core/css/yui-cal.css');
  end

  # This returns the Edit View of a input of type calendar in HTML form
  # protected function
  def get_field_edit_html
    return '<HTML NOT IMPLEMENT YET>'
  end

  # This returns the Edit View of a input of type calendar in Javascript form
  # protected function
  def get_field_edit_js
    # TODO: add JS rendering when generating JS fields class for client side rendering
    return '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit for an input of type calendar in TPL/Smarty form
  # protected function
  def get_field_edit_rtpl
    case @cal_type
      when'basic'
        return self.get_basic_edit_rtpl
    end
  end

  # This returns the View of type edit for an input of type basic calendar in TPL/Smarty form
  # protected function
  def get_basic_edit_rtpl
    # TODO: replace hardcoded calbutton image with dynamic call for to get base file path
    # also replace show calendar with Show "Field String" Calendar, call to i18N func
    size = 'size="' + @columns.to_s + '"'
    btn_id = 'show-' + @id + '-cal'
    btn_title = 'Show Calendar'

    # add the script to register the calendar
    # R8 DEBUG
    #    $GLOBALS['log']->log('debug',"R8.fields.registerCal('".$this->id."','".$btn_id."','".$this->id."-cal');");
    #    $GLOBALS['ctrl']->addJSExeScript(
    #        array(
    #          'content' => "R8.fields.registerCal('".$this->id."','".$btn_id."','".$this->id."-cal');",
    #          'race_priority' => 'low'
    #        )
    #    );

    return '
    <input type="text" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="{%=' + @model_name + '[:' + @name + ']%}" ' + size + ' />
    <button type="button" id="' + btn_id + '" title="' + btn_title + '">
      <img src="core/images/calendarbutton.gif" width="18" height="18" alt="Calendar" />
    </button>
    ';
  end

  # This returns the View of type view for an input of type calendar in TPL/Smarty form
  # protected function
  def get_field_display_rtpl
    return '{%=' + @model_name + '[:' + @name + ']%}'
  end

  def get_field_display_html
    return @value
  end

  def get_field_display_js
    return '<JS DISPLAY NOT IMPLEMENTED YET>'
  end

  # This returns the View of type list for an input of type calendar in TPL/Smarty form
  # protected function
  def get_field_list_rtpl
    return '{%=' + @model_name + '[:' + @name + ']%}'
  end

  def get_field_list_html
    return @value
  end

  def get_field_list_js
    return '<JS NOT IMPLEMENTED YET>'
  end
end
