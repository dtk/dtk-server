#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Fieldselect < Fieldbase
  attr_accessor :default_class, :option_str

  def initialize(field_meta)
    super(field_meta)

    @default_class = 'r8-select'
    @option_str = ''

    self.add_class(@default_class)
    self.set_options(field_meta[:options])
  end

  def set_options(options)
    @option_str = ''
    options.each do |value, display|
      #      @option_str << '<option value="' + value + '" selected="{%=' + @model_name + '[:' + @name + ']%}">' + display + '</option>'
      @option_str << '<option value="' + value + '" {%=' + @model_name + '[:' + @name + '_options_list][:' + value + '_selected]%}">' + display + '</option>'
    end
  end

  # This returns the Edit View of a select HTML form element
  # protected function
  def get_field_edit_html
    '<HTML NOT IMPLEMENTED YET>'
  end

  # This returns the Edit View of a input of type select in Javascript form
  # protected function
  def get_field_edit_js
    # TODO: add JS rendering when generating JS fields class for client side rendering
    '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit for an input of type select in rtpl form
  # protected function
  def get_field_edit_rtpl
    (!@multiple.nil? && @multiple != '') ? multiple = @multiple : multiple = ''

    select_str = '<select id="' + @id + '" name="' + @name + '" ' + multiple + '>'
    select_str << @option_str
    select_str << '</select>'

    select_str
  end

  # This returns the View of type view for an input of type select in TPL/Smarty form
  # protected function
  def get_field_display_rtpl
    # TODO: revisit when implementing save/display of multiselct values
    #    if(isset($this->multiple) && $this->multiple != '')
    #      $multiple = $this->multiple;
    #    else $multiple = '';

    field_string = '{%=' + @model_name + '[:' + @name + '_display]%}'
    field_string
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
    field_string
  end
end