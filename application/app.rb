# This file contains your application, it requires dependencies and necessary
# parts of the application.
#
# It will be required from either `config.ru` or `start.rb`

#TODO: add all required gem includes here, or where appropriate
require 'rubygems'
require 'ramaze'
require 'json'
require 'yaml'

require File.expand_path('../utils/utils', File.dirname(__FILE__))
#utils needed in config file
require File.expand_path('config/config.rb',File.dirname(__FILE__))
require File.expand_path('config/routes.rb',File.dirname(__FILE__))


APPLICATION_DIR = File.expand_path('../' + R8::Config[:application_name], File.dirname(__FILE__))
UTILS_DIR = File.expand_path('../utils', File.dirname(__FILE__))
SYSTEM_DIR = File.expand_path('../system', File.dirname(__FILE__))

#CORE_BASE_PATH  = File.expand_path(SYSTEM_DIR+'/core', File.dirname(__FILE__)) + "/"

require SYSTEM_DIR + '/view.r8.rb'
require SYSTEM_DIR + '/template.r8.rb'
require UTILS_DIR + '/internal/log.rb'

#TODO: should load application strings here
#user_lang should be in user prefs, or pulled/set from app default in config
user_lang = R8::Config[:default_language] = "en.us"
#require 'i18n/' + user_lang + '.rb' #TBD: should be conditionally loaded

# Here goes your database connection and options:
require SYSTEM_DIR + '/db'
DBinstance = XYZ::DB.create(R8::Config[:database])

#removing memory caching for now, doesnt seem like it should be included here
#require SYSTEM_DIR + '/cache'

#TBD: have system dir container
#require SYSTEM_DIR + 'messaging'

# Make sure that Ramaze knows where you are
Ramaze.options.roots = [__DIR__]
#Ramaze.options.mode = :live
# Initialize controllers and models

require __DIR__('model/init')
require __DIR__('controller/init')


