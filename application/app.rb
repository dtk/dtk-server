# This file contains your application, it requires dependencies and necessary
# parts of the application.
#
# It will be required from either `config.ru` or `start.rb`

require 'rubygems'
require 'ramaze'

require File.expand_path('../utils/utils', File.dirname(__FILE__))
SYSTEM_DIR = File.expand_path('../system', File.dirname(__FILE__)) + "/"
require SYSTEM_DIR + '/cache'
#TBD: have system dir container
require SYSTEM_DIR + 'messaging'
CORE_MODEL_DIR  = File.expand_path('../core_model', File.dirname(__FILE__)) + "/"



# Make sure that Ramaze knows where you are
Ramaze.options.roots = [__DIR__]
#Ramaze.options.mode = :live
# Initialize controllers and models
require __DIR__('model/init')
require __DIR__('controller/init')

