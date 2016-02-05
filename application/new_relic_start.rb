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
# Use this file directly like `ruby start.rb` if you don't want to use the
# `ramaze start` command.
# All application related things should go into `app.rb`, this file is simply
# for options related to running the application locally.
require 'rubygems'
require 'newrelic_rpm'
require 'newrelic-sequel'

require File.expand_path('app', File.dirname(__FILE__))

::NewRelic::Agent.manual_start

is_development = ARGV[0] || false

unless is_development
  rotating_logger = Logger.new('r8server.log', 'daily')
  Ramaze::Log.loggers = [rotating_logger]
  Ramaze::Log.level = Logger::DEBUG
else
  puts '**** DEVELOPMENT MODE - NO LOGS ****'
end

class DTKServerTenant5
  def initialize(app)
    @app    = app
  end

  def call(env)
    @app.call(env)
  end
  include ::NewRelic::Agent::Instrumentation::Rack
end

Ramaze.middleware! :dev do |m|
  m.use DTKServerTenant5
  m.run Ramaze.middleware
end

# TODO: use this when upgrade to Ramaze 2012.12.08
# Ramaze.middleware :dev do
#   use DTKServerTenantNew5
#   run Ramaze.core
# end

Ramaze.start(adapter: :thin, port: R8::Config[:server_port], file: __FILE__)