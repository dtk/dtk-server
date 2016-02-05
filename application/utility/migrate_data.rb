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

unless ARGV[0]
  puts 'You need to pass Tenant Name! (e.g. ruby utility/migrate_data.rb dtk16)'
  exit
end

puts 'WARNING!'
puts
puts '************* PROVIDED DATA *************'
puts " TENANT-ID:    #{ARGV[0]}"
puts '*****************************************'
puts 'Make sure that provided data is correct, and press ENTER to continue OR CTRL^C to stop'
a = $stdin.gets

root = File.expand_path('../', File.dirname(__FILE__))

require root + '/app'
XYZ::Model.migrate_data_new({ db: DBinstance }, ARGV[0])