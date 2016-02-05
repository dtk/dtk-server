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

class Fieldmultiselect < Fieldselect
  attr_accessor :default_class, :multiple

  def initialize(field_meta)
    super(field_meta)
    @defaultClass = 'r8-multiselect'
    @multiple = 'multiple="multiple"'
  end

  # this is overriden in order to set the multiselected which is needed
  # for correct compiling of the js template
  def set_options(options)
    @option_str = ''
    options.each do |value, display|
      @option_str << '<option value="' + value + '" multiselected="{%=' + @model_name + '[:' + @name + ']%}">' + display + '</option>'
    end
  end

  # This returns the View of type view for an input of type multiselect in TPL/Smarty form
  # protected function
  def get_field_display_rtpl
    field_string = '{%=' + @model_name + '[:' + @name + ']%}'
    field_string
  end

  # This returns the View of type list for an input of type multiselect in TPL/Smarty form
  # protected function
  def get_field_list_rtpl
    field_string = '{%=' + @model_name + '[:' + @name + ']%}'
    field_string
  end
end