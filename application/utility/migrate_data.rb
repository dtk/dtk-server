#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))

require root + '/app'
XYZ::Model.migrate_data_new(:db => DBinstance)
