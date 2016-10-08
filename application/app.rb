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
# TODO: need to cleanup
# This file contains your application, it requires dependencies and necessary
# parts of the application.
#
# It will be required from either `config.ru` or `start.rb`


##### temp until convert to DTK
module XYZ; end
Object.send(:remove_const, :DTK) rescue nil
DTK = XYZ
####

require 'bundler/setup'
require 'ramaze'
require 'json'
require 'yaml'
require 'looksee'

# TODO: probably better way to do this; below makes sure that if program staretd in different directory than this, that still finds helpers
helper_paths = Innate.options[:helpers_helper][:paths] || []
unless helper_paths.include?(File.dirname(__FILE__))
  Innate.options[:helpers_helper][:paths] = [File.dirname(__FILE__)] + helper_paths
end

# TODO: for testing; signal to dump thread info
#trap 'TTIN' do
#  Thread.list.each do |thread|
#    puts "------------------- Thread TID-#{thread.object_id.to_s} -----------------\n"
#    pp thread.backtrace
#    puts "---------------------------------------------------------------------------\n"
#  end
#end

require 'bundler/setup'
require File.expand_path('require_first', File.dirname(__FILE__))

# load common gem or use local dir if available
dtk_require_common_library()

module DTK::GlobalForDSL
  Error  = ::DTK::Error
  ErrorUsage  = ::DTK::ErrorUsage
end
# DTK::GlobalForDSL defs must before "require 'dtk_dsl'"
require 'dtk_dsl'

SYSTEM_ROOT_PATH = File.expand_path('../', File.dirname(__FILE__))
LIB_DIR = "#{SYSTEM_ROOT_PATH}/lib"
UTILS_BASE_DIR = "#{SYSTEM_ROOT_PATH}/utils"
UTILS_DIR = "#{UTILS_BASE_DIR}/internal"

# TODO: make that log  dont need config values
r8_require("#{UTILS_DIR}/log")
r8_require("#{LIB_DIR}/error") #TODO: see if can move this to be a require in lib/dtk_server.rb
r8_require("#{UTILS_DIR}/hash_object")
r8_require("#{UTILS_DIR}/message_queue")
r8_require("#{UTILS_DIR}/ssh_cipher")

r8_require("#{LIB_DIR}/configuration") #TODO: see if can move this to be a require in lib/dtk_server.rb
DTK::Configuration.instance.set_configuration()

APPLICATION_DIR = File.expand_path("../#{R8::Config[:application_name]}", File.dirname(__FILE__))
SYSTEM_DIR = File.expand_path('../system', File.dirname(__FILE__))

r8_require("#{SYSTEM_DIR}/utility")
r8_require("#{SYSTEM_DIR}/common_mixin")
r8_require("#{UTILS_BASE_DIR}/utils")
r8_require("#{LIB_DIR}/dtk_server")
r8_require('config/routes.rb')

# r8_require("#{SYSTEM_DIR}/view")
# r8_require("#{SYSTEM_DIR}/template")

# TODO: should load application strings here
# user_lang should be in user prefs, or pulled/set from app default in config
# user_lang = R8::Config[:default_language] || "en.us"
# require 'i18n/' + user_lang + '.rb' #TBD: should be conditionally loaded

# Here goes your database connection and options:
r8_require("#{LIB_DIR}/db")
DBinstance = ::DTK::DB.create(R8::Config[:database])

# removing memory caching for now, doesnt seem like it should be included here
# require SYSTEM_DIR + '/cache'

# TBD: have system dir container
# require SYSTEM_DIR + 'messaging'

# Make sure that Ramaze knows where you are
Ramaze.options.roots = [__DIR__]
# Ramaze.options.mode = :live
# Initialize controllers and models

r8_require('model/init')
r8_require('controller/init')
