#!/usr/bin/env ruby
root = File.expand_path('../../', File.dirname(__FILE__))
require root + '/app'
require 'pp'

# Object.et_object(id_handle,opts={})
#The function returns the model object corresponding to the object given by id_handle; it turnns just the scalar attributes; once you have the Ruby object ob actual and virtual attributes such as foo can be returned using obj[:foo]

module XYZ
  #IDHandle[] constructor for handle on object; it takes a hash that can be of two forms:
  #  IDHandle[:c => c, :uri => uri] or IDHandle[:c => c, :guid => id]

  uri = ARGV[0] || '/project/p1/node/i-63775608'
  object = Object.get_object(IDHandle[:c => 2, :uri => uri])
  pp [object.class,object]

  #illustrates call by id
  id_handle = IDHandle[:c => 2, :guid => object[:id]]
  pp [:call_by_id, object[:id],Object.get_object(id_handle)]

  #TBD: show different opts, which is a hash it can take; for is
  #Object.get_object(id_handle,opts)
end
