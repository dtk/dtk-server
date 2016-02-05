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
puts "\tWARNING!\tWARNING!\tWARNING!\tWARNING!"
puts
puts 'Make sure that your run this script ONLY ONCE, multiple runs will cause data corruption. press ENTER key to continue OR CTRL^C to stop'
a = $stdin.gets
puts 'Hashing passwords ... '

require root + '/app'

default_project = ::DTK::Project.get_all(::DTK::ModelHandle.new(c = 2, :project)).first
::DTK::Model.get_objs(default_project.model_handle(:user), { cols: ::DTK::User.common_columns })

session = ::DTK::CurrentSession.new
session.set_user_object(default_project.get_field?(:user))
session.set_auth_filters(:c, :group_ids)

users = ::DTK::Model.get_objs(default_project.model_handle(:user), { cols: [:id, :password] })

users.each do |user|
  user.update(password: ::DTK::DataEncryption.hash_it(user[:password]))
end

::DTK::Model.update_from_rows(default_project.model_handle(:user), users)

puts 'Passwords have been hashed successfully!'