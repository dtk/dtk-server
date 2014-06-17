#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'
# utils/internal/serialize_to_json.rb
include XYZ
# monkey patch
module ActiveSupport
  class OrderedHash < ::Hash
    def pretty_print(q)
#      q.group(0, "#<OrderedHash", "}>") {
      q.group(0,"","}") {
#        q.breakable " "
        q.text "{"
        q.group(1) {
          q.seplist(self) {|pair|
            q.pp pair.first
            q.text "=>"
            q.pp pair.last
          }
        }
      }
    end
  end
end
=begin
pp DB_REL_DEF.each_value.map{|x|x.keys}.flatten.uniq
next_level = Hash.new
DB_REL_DEF.each_value.each do |x|
  x.each do |k,v|
    next unless v.kind_of?(Hash) and v.values.first.kind_of?(Hash)
    next_level[k] ||= Array.new
    new_keys = v.values.map{|u|u.keys}.flatten
    next_level[k] = (next_level[k] + new_keys).uniq
  end
end
=end
ordered_top_level_keys = 
  [
   :schema,
   :table,
   :columns,
   :virtual_columns,
   :many_to_one,
   :one_to_many
  ]

next_level_keys = {
  :columns=>
  [
   :type,
   :default,
   :size,
   :foreign_key_rel_type,
   :on_delete,
   :on_update,
   :ret_keys_as_symbols,
   :hidden
  ],
  :virtual_columns=>
  [
   :type,
   :remote_dependencies,
   :hidden,
   :possible_parents,
   :local_dependencies,
   :sql_fn,
   :path]
}


DB_REL_DEF.each do |model_name,info|
  pp [:model_name,model_name];
  ordered_hash = ActiveSupport::OrderedHash.new()
  ordered_top_level_keys.each do |k|
    next unless info.has_key?(k)
    val = info[k]
    if next_level = next_level_keys[k]
      val = Hash.new
      info[k].each do |nk,nv|
        nested_oh = ActiveSupport::OrderedHash.new()
        next_level.each{|nlk|nested_oh[nlk] = nv[nlk] if nv.has_key?(nlk)}
        val[nk] = nested_oh
      end
    end
    ordered_hash[k] = val
  end
  pp ordered_hash
  puts "------------------------------------------------------"
end






