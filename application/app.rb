#TODO: need to cleanup and determien what is neededed ordering of requires
# This file contains your application, it requires dependencies and necessary
# parts of the application.
#
# It will be required from either `config.ru` or `start.rb`

#TODO: add all required gem includes here, or where appropriate
require 'rubygems'
require 'bundler/setup'
require 'ramaze'
require 'json'
require 'yaml'

#TODO: probably better way to do this; below makes sure that if program staretd in different directory than this, that still finds helpers
helper_paths = Innate.options[:helpers_helper][:paths]||[]
unless helper_paths.include?(File.dirname(__FILE__))
  Innate.options[:helpers_helper][:paths] = [File.dirname(__FILE__)] + helper_paths
end

##### temp until convert to DTK
module XYZ
end
DTK = XYZ

require File.expand_path('require_first', File.dirname(__FILE__))
r8_require_common_lib('auxiliary')

#TODO: make that log  dont need config values 
r8_require('../utils/internal/log')
r8_require('../utils/internal/dsl_parsing_aux')
r8_require('../utils/internal/error')
r8_require('../utils/internal/hash_object')

r8_require('../utils/internal/configuration')
DTK::Configuration.instance.set_configuration()

APPLICATION_DIR = "../#{R8::Config[:application_name]}"
UTILS_DIR = '../utils'
SYSTEM_DIR = '../system'

r8_require("#{SYSTEM_DIR}/utility.r8.rb")
r8_require("#{UTILS_DIR}/utils")

LIB_DIR = File.expand_path('../lib', File.dirname(__FILE__))
r8_require("#{LIB_DIR}/model")

r8_require('config/routes.rb')

r8_require("#{SYSTEM_DIR}/view.r8.rb")
r8_require("#{SYSTEM_DIR}/template.r8.rb")
r8_require("#{UTILS_DIR}/internal/log.rb")

#TODO: should load application strings here
#user_lang should be in user prefs, or pulled/set from app default in config
user_lang = R8::Config[:default_language] || "en.us"
#require 'i18n/' + user_lang + '.rb' #TBD: should be conditionally loaded

# Here goes your database connection and options:
r8_require("#{SYSTEM_DIR}/db")
DBinstance = XYZ::DB.create(R8::Config[:database])

#removing memory caching for now, doesnt seem like it should be included here
#require SYSTEM_DIR + '/cache'

#TBD: have system dir container
#require SYSTEM_DIR + 'messaging'

# Make sure that Ramaze knows where you are
Ramaze.options.roots = [__DIR__]
#Ramaze.options.mode = :live
# Initialize controllers and models

r8_require('model/init')
r8_require('controller/init')

