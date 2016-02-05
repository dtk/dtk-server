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

class Fieldcheckbox < Fieldbase
  attr_accessor :default_class

  def initialize(field_meta)
    super(field_meta)
    @default_class = 'r8-checkbox'
    self.add_class(@default_class)
  end

  # This returns the Edit View of a input of type checkbox HTML form,
  # protected function
  def get_field_edit_html
    #    if(!@value.nil? && (@value == '1' || @value == 1)) then
    if (!@value.nil? && @value == true) then
      checked = 'checked="true"'
    else
      checked = ''
    end
    '<input type="checkbox" id="' + @id + '" name="' + @name + '" value="1" class="' + @class_txt + '" ' + @checked + ' />'
  end

  # This returns the Edit View of a input of type text in Javascript form
  # protected function
  def get_field_edit_js
    # TODO: add JS rendering when generating JS fields class for client side rendering
    '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit of a input for the checkbox in TPL/Smarty form
  # TODO: revisit and add leading hidden field for proper handling of unchecked form submissions
  # protected function
  def get_field_edit_rptl
    '<input type="hidden" id="' + @id + '-hidden" name="' + @name + '" value="false" />
    <input type="checkbox" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="true" {%=' + @model_name + '[:' + @name + '_checked]%}" />
    '
  end

  # This returns the View of type view of a input for the checkbox in TPL/Smarty form
  # protected function
  # TODO: revisit and add leading hidden field for proper handling of unchecked form submissions
  def get_field_display_rtpl
    '<input disabled="disabled" type="checkbox" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="true" {%=' + @model_name + '[:' + @name + '_checked]%}" />'
  end

  def get_field_display_html
    '<HTML Display NOT IMPLEMENTED YET>'
  end

  # This returns the View of type list of a input for the checkbox in TPL/Smarty form
  # protected function
  def get_field_list_rtpl
    '<input disabled="disabled" type="checkbox" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="1" checked="{%=' + @model_name + '[:' + @name + ']%}" />'
  end

  def get_field_list_html
    '<HTML LIST NOT IMPLEMENTED YET>'
  end

  def get_field_list_js
    '<JS LIST NOT IMPLEMENTED YET>'
  end
end