

class Fieldcalendar < Fieldbase

  attr_accessor :default_class,:read_only,:calType

  def initialize(fieldMeta)
    super(fieldMeta)
    @default_class = 'r8-cal'
    self.addClass(@default_class)
    @read_only = false

    (!fieldMeta['cols'].nil?) ? @columns = fieldMeta['cols'] : @columns = 40
    (!fieldMeta['calType'].nil?) ? @cal_type = fieldMeta['calType'] : @cal_type = 'basic'

  end
  def set_includes(r8view_ref)
    super(r8view_ref)
    r8view_ref.add_to_js_require("http://yui.yahooapis.com/2.7.0/build/element/element.js")
    r8view_ref.add_to_js_require("http://yui.yahooapis.com/2.7.0/build/button/button.js")
    r8view_ref.add_to_js_require("http://yui.yahooapis.com/2.7.0/build/calendar/calendar.js")
    r8view_ref.add_to_js_require("http://yui.yahooapis.com/2.7.0/build/container/container.js")

    r8view_ref.add_to_css_require("http://yui.yahooapis.com/2.7.0/build/container/assets/skins/sam/container.css");
     r8view_ref.add_to_css_require("core/css/yui-cal.css");
  end

   # This returns the Edit View of a input of type calendar in HTML form
   #protected function
  def getFieldEditHTML()
    return '<HTML NOT IMPLEMENT YET>'
  end

   # This returns the Edit View of a input of type calendar in Javascript form
   #protected function
  def getFieldEditJS()
#TODO: add JS rendering when generating JS fields class for client side rendering
    return '<JS NOT IMPLEMENT YET>'
  end

   # This returns the View of type edit for an input of type calendar in TPL/Smarty form
   #protected function
  def getFieldEditTPL()
    case @cal_type
      when"basic"
        return self.getBasicEditTPL
    end
  end

   # This returns the View of type edit for an input of type basic calendar in TPL/Smarty form
   #protected function
  def getBasicEditTPL()
#TODO: replace hardcoded calbutton image with dynamic call for to get base file path
#also replace show calendar with Show "Field String" Calendar, call to i18N func
    size = 'size="' + @columns.to_s + '"'
    btnId = 'show-' + @id + '-cal'
    btnTitle = 'Show Calendar'

    #add the script to register the calendar
#R8 DEBUG
#    $GLOBALS['log']->log('debug',"R8.fields.registerCal('".$this->id."','".$btnId."','".$this->id."-cal');");
#    $GLOBALS['ctrl']->addJSExeScript(
#        array(
#          'content' => "R8.fields.registerCal('".$this->id."','".$btnId."','".$this->id."-cal');",
#          'race_priority' => 'low'
#        )
#    );

    return '
    <input type="text" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="{%=' + @obj_name + '[:' + @name + ']%}" ' + size + ' />
    <button type="button" id="' + btnId + '" title="' + btnTitle + '">
      <img src="core/images/calendarbutton.gif" width="18" height="18" alt="Calendar" />
    </button>
    ';
  end

   # This returns the View of type view for an input of type calendar in TPL/Smarty form
   #protected function
  def getFieldDisplayTPL()
    return '{%=' + @obj_name + '[:' + @name + ']%}'
  end

  def getFieldDisplayHTML()
    return @value
  end

  def getFieldDisplayJS()
    return '<JS DISPLAY NOT IMPLEMENTED YET>'
  end

  # This returns the View of type list for an input of type calendar in TPL/Smarty form
  #protected function
  def getFieldListTPL()
    return '{%=' + @obj_name + '[:' + @name + ']%}'
  end

  def getFieldListHTML()
    return @value
  end

  def getFieldListJS()
    return '<JS NOT IMPLEMENTED YET>'
  end

end