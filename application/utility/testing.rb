#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'

# DEBUG SNIPPET >>> REMOVE <<<
require 'ap'
ap DTK::ServiceModule.all

filter = {
   :filter => [:eq, :username, 'dtk16'],
   :columns => [:c, :id, :username, :password, :user_groups]
}
ap user = DTK::User.where(filter).first
ap ">>>>>>>>>>"

filter = {
  :filter => [:eq, :display_name, 'dtk_server'],
  :columns => [:id, :display_name, :namespace_id, :namespace]
}

ap DTK::ComponentModule.where(filter).first