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

require File.expand_path('field.text.rb', File.dirname(__FILE__))

class Fieldurl < Fieldtext
  def initialize(field_meta)
    super(field_meta)
  end

  # This returns the View of a input of type text in TPL/Smarty form
  # protected function
  def get_field_display_text_rtpl
    (!@field_meta[:target].nil? && @field_meta[:target] != '') ? target = 'target="' + @field_meta[:target] + '"' : target = ''

    '<a href="{%=' + @model_name + '[:' + @name + ']%}" ' + target + '>{%=' + @model_name + '[:' + @name + ']%}</a>'
  end

  def get_field_list_text_rtpl
    (!@field_meta[:target].nil? && @field_meta[:target] != '') ? target = 'target="' + @field_meta[:target] + '"' : target = ''

    '<a href="{%=' + @model_name + '[:' + @name + ']%}" ' + target + '>{%=' + @model_name + '[:' + @name + ']%}</a>'
  end
end