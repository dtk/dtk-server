#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))

require root + '/app'
XYZ::Model.db_rebuild(DBinstance)


