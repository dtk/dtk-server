#!/usr/bin/env ruby
# complete hack, but is aux fn
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'
# utils/internal/serialize_to_json.rb
include XYZ

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
   :many_to_one,
   :one_to_many,
   :virtual_columns,
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
   :hidden,
   :local_dependencies,
   :sql_fn,
   :possible_parents,
   :path,
   :remote_dependencies
  ]
}

RemoteDepCols = 
  [
   :model_name,
   :alias,
   :sequel_def,
   :convert,
   :join_type,
   :filter,
   :join_cond,
   :cols
  ]

def proc_remote_dep(rem_dep)
  conditions = rem_dep.kind_of?(Array) ? rem_dep : rem_dep.values.first
  proc_conditions = conditions.map do |cond|
    ordered_hash = ActiveSupport::OrderedHash.new()
    RemoteDepCols.each do |k|
      ordered_hash[k] = cond[k] if cond.has_key?(k)
    end
    ordered_hash
  end
  rem_dep.kind_of?(Array) ? proc_conditions : {rem_dep.keys.first => proc_conditions}
end


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
        next_level.each do |nlk|
          if nv.has_key?(nlk)
            nested_oh[nlk] = (nlk == :remote_dependencies ? proc_remote_dep(nv[nlk]) : nv[nlk])  
          end
        end
        val[nk] = nested_oh
      end
    end
    ordered_hash[k] = val
  end
  pp ordered_hash
  puts "------------------------------------------------------"
end







