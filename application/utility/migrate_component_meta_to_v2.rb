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
module_name = ARGV[0]
server = R8Server.new('superuser', groupname: 'all')
new_meta_full_path = server.migrate_metafile(module_name)
STDOUT << new_meta_full_path
STDOUT << "\n"
