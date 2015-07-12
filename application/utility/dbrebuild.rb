#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))

require root + '/app'
model_names = ARGV[0] && ARGV[0].split(',').map(&:to_sym)
XYZ::Model.db_rebuild(model_names, db: DBinstance)
