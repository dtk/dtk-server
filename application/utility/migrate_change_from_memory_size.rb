#!/usr/bin/env ruby
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
root = File.expand_path('../', File.dirname(__FILE__))

puts
puts "Script that changes references from 'memory_size' to 'instance_size'"
puts

require root + '/app'
include DTK
default_project = Project.get_all(ModelHandle.new(c = 2, :project)).first
Model.get_objs(default_project.model_handle(:user), { cols: User.common_columns })

session = CurrentSession.new
session.set_user_object(default_project.get_field?(:user))
session.set_auth_filters(:c, :group_ids)
sp_hash = {
 cols: [:id, :display_name],
 filter: [:eq, :display_name, 'memory_size']
}
attr_mh = default_project.model_handle(:attribute)
memory_size_attrs = Model.get_objs(attr_mh, sp_hash)
number_of_changes = memory_size_attrs.size
if number_of_changes == 0
  puts "No instances of 'memory_size' found"
else
  update_rows = memory_size_attrs.map { |r| r.merge(display_name: 'instance_size') }
  Model.update_from_rows(attr_mh, update_rows)
  puts "#{number_of_changes.to_s} instances of 'memory_size' have been converted to 'instance_size'"
end