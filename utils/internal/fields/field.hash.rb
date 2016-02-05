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

class Fieldhash < Fieldbase
  attr_accessor :default_class

  def initialize(field_meta)
    super(field_meta)

    @default_class = 'r8-hash'

    self.add_class(@default_class)
  end

  def get_field_edit_html
    '<HTML NOT IMPLEMENTED YET>'
  end

  def get_field_edit_js
    # TODO: add JS rendering when generating JS fields class for client side rendering
    '<JS NOT IMPLEMENT YET>'
  end

  def get_field_edit_rtpl
    rows = 10
    cols = 50
    value = hash_to_string_fn()
    name = @field_meta[:override_name] || @name
    field_string =  '<textarea id="' + @id + '" name="' + name + '" class="' + @class_txt + '" rows=' + rows.to_s + ' cols=' + cols.to_s + '>' + value + '</textarea>'
    field_string
  end

  def get_field_display_rtpl
    hash_to_string_fn()
  end

  def get_field_list_rtpl
    hash_to_string_fn()
  end

  private

  def hash_to_string_fn
    "{%=lambda{|a|(a.kind_of?(String) ? a : JSON.pretty_generate(a)) if a}.call(#{@model_name}[:#{@name}])%}"
  end
end