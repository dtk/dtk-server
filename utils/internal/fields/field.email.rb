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

class Fieldemail < Fieldbase
  attr_accessor :columns, :default_class, :readonly

  def initialize(field_meta)
    super(field_meta)

    @columns = 0
    # TODO: move this to a CSS config file so it can be changes easier
    @default_class = 'r8-email'
    @readonly = false
    self.add_class(@default_class)
    (!field_meta['cols'].nil?) ? @columns = field_meta['cols'] : @columns = 40
  end

  # This returns the Edit View of a input of type text in HTML form
  # protected function
  def get_field_edit_html
    if (@columns >= 1)
    then @size = 'size="' + @columns.to_s + '"'
    else @size = ''
    end

    '<input type="text" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="' + @value + '" ' + @size + ' />'
  end

  # This returns the Edit View of a input of type text in Javascript form
  # protected function
  def get_field_edit_js
    # TODO: add JS rendering when generating JS fields class for client side rendering
    if (@columns >= 1)
    then @size = 'size="' + @columns.to_s + '"'
    else @size = ''
    end
    '<JS NOT IMPLEMENT YET>'
  end

  # This returns the View of type edit for an input of type email in TPL/Smarty form
  # protected function
  def get_field_edit_rtpl
    if (@columns >= 1)
    then @size = 'size="' + @columns.to_s + '"'
    else @size = ''
    end
    '<input type="text" id="' + @id + '" name="' + @name + '" class="' + @class_txt + '" value="{%=' + @model_name + '[:' + @name + ']%}" ' + @size + ' />'
  end

  # This returns the View of type view for an input of type email in TPL/Smarty form
  # protected function
  def get_field_display_rtpl
    '<a href="mailto:{%=' + @model_name + '[:' + @name + ']%}">{%=' + @model_name + '[:' + @name + ']%}</a>'
  end

  # This returns the View of type list for an input of type email in TPL/Smarty form
  # protected function
  def get_field_list_rtpl
    '<a href="mailto:{%=' + @model_name + '[:' + @name + ']%}">{%=' + @model_name + '[:' + @name + ']%}</a>'
  end
end