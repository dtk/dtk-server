# Use this file directly like `ruby start.rb` if you don't want to use the
# `ramaze start` command.
# All application related things should go into `app.rb`, this file is simply
# for options related to running the application locally.

require File.expand_path('app', File.dirname(__FILE__))

rotating_logger = Logger.new('r8server.log', 'daily')
Ramaze::Log.loggers = [rotating_logger]
Ramaze::Log.level = Logger::WARN

Ramaze.start(:adapter => :thin, :port => 7000, :file => __FILE__)
