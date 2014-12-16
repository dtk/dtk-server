#!/usr/bin/env rackup
#
# config.ru for ramaze apps
# use thin >= 1.0.0
# thin start -R config.ru
#
# rackup is a useful tool for running Rack applications, which uses the
# Rack::Builder DSL to configure middleware and build up applications easily.
#
# rackup automatically figures out the environment it is run in, and runs your
# application as FastCGI, CGI, or standalone with Mongrel or WEBrick -- all from
# the same configuration.
#
# Do not set the adapter.handler in here, it will be ignored.
# You can choose the adapter like `ramaze start -s mongrel` or set it in the
# 'start.rb' and use `ruby start.rb` instead.

require ::File.expand_path('../app', __FILE__)

rotating_logger = Logger.new("log/#{ENV['RACK_ENV']}.log", 'weekly', 5)
Ramaze::Log.loggers = [rotating_logger]
Ramaze::Log.level = Logger.const_get(R8::Config[:log][:level].upcase)

Ramaze.options.mode = :live
Ramaze.start(:root => __DIR__, :started => true)
run Ramaze
