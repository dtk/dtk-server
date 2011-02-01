#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'
#utils/internal/serialize_to_json.rb
include XYZ
#monkey patch
module ActiveSupport
  class OrderedHash < ::Hash
    def pretty_print(q)
#      q.group(0, "#<OrderedHash", "}>") {
      q.group(0,"","}") {
        q.breakable " "
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

ordered_top_level_keys = 
  [
   :schema,
   :table,
   :columns,
   :virtual_columns,
   :many_to_one,
   :one_to_many
  ]


#pp DB_REL_DEF.each_value.map{|x|x.keys}.flatten.uniq

DB_REL_DEF.each do |model_name,info|
  pp [:model_name,model_name];
  ordered_hash = ActiveSupport::OrderedHash.new()
  ordered_top_level_keys.each{|k|ordered_hash[k] = info[k] if info.has_key?(k)}
  pp ordered_hash
  puts "------------------------------------------------------"
end






