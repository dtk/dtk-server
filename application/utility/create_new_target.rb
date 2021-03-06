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
# general initial
require File.expand_path('common', File.dirname(__FILE__))
options = {}
OptionParser.new do|opts|
   opts.banner = 'Usage: create_new_target.rb USER-NAME TARGET-NAME'
end.parse!
username = ARGV[0]
target_name = ARGV[1]
server = R8Server.new(username)
server.create_new_target?(target_name)