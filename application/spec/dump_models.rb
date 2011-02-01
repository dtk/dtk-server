#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'
#utils/internal/serialize_to_json.rb
include XYZ
ordered_top_level_keys = 
  [
   :schema,
   :table,
   :model_class,
   :columns,
   :virtual_columns,
   :many_to_one,
   :one_to_many,

   :relation_type,
   :has_ancestor_field,
   :parent_id,
   :local_id,
   :id
  ]


#pp DB_REL_DEF.each_value.map{|x|x.keys}.flatten.uniq
=begin
DB_REL_DEF.each do |model_name,info|
 # pp [:model_name,model_name];pp info; puts "------------------------------------------------------"
end
=end
#ordered_hash = ActiveSupport::OrderedHash.new()




