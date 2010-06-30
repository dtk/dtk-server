#!/usr/bin/env ruby
root = File.expand_path('../../', File.dirname(__FILE__))
require root + '/app'
require 'pp'

#Object.get_instance_or_factory(id_handle,href_prefix=nil,opts={})
#Returns a hash that can contain an object and its children depending on what is passed in opts. href_prefix is used for rest calls when need to return refs back.  I wil need to document all the options and we need to clean this up. Below is way to return object and its childen (without hrefs)
module XYZ
  uri = ARGV[0] || '/project/p1/node/i-63775608'
  opts = Hash.new
  opts[:no_hrefs] = true
  opts[:depth] = :deep
  opts[:no_null_cols] = true

  hash = Object.get_instance_or_factory(IDHandle[:c => 2, :uri => uri],nil,opts)
  pp [:nested_object,hash]
end
