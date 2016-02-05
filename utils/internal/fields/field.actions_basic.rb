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

class Fieldactions_basic < Fieldbase
  def initialize(field_meta)
    super(field_meta)
  end

  def get_field_list_rtpl
    field_string = ''

    @field_meta[:action_list].each do |action|
      field_string != '' ? field_string << @field_meta[:action_seperator] : nil
      label = '{%=_' << @model_name << '[:i18n][:' << action[:label] << ']%}'

      (!action[:target].nil? && action[:target] != '') ? target = 'target="' + action[:target] + '"' : target = ''
      field_string << '<a href="' << R8::Config[:base_uri] << '/xyz/' << action[:route] << '"' << target << '>' << label << '</a>'
    end

    field_string
  end
end