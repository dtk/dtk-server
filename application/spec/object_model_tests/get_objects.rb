#!/usr/bin/env ruby
root = File.expand_path('../../', File.dirname(__FILE__))
require root + '/app'
require 'pp'

#Object.get_objects(relation_type,c,where_clause=nil,field_set=nil)
#Returns a list of objects whose type are relation_type and contrsained by the where clause, which can have a number of forms; simplest is hash each element being attributes (note: might deprecate "field_set since there is some reasons related to virtual attributes why filtering should be done after getting object, nit when doing query
module XYZ

  relation_type = :node
  c = 2
  objects = Object.get_objects(relation_type,c)
  pp [:no_where_clause,objects]
  filtered_objects = Object.get_objects(relation_type,c,{:display_name=>"i-37dd8c5c",:os=>"ubuntu 9.10"})
  pp [:filtered_objects, filtered_objects]
end
