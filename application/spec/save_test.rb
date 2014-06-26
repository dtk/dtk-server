#!/usr/bin/env ruby
require 'rubygems'
require 'tmpdir'
require 'json'
require 'restclient'
library_name = ARGV[0]
file_name = ARGV[1]


  def edit_data(json_data)
      filename = "reactor-"
      0.upto(20) { filename += rand(9).to_s }
      filename << ".js"
      filename = File.join(Dir.tmpdir, filename)
      tf = File.open(filename, "w")
      tf.sync = true
      tf.puts json_data
      tf.close
      raise "Please set EDITOR environment variable" unless system("#{ENV["EDITOR"] || "vi"} #{tf.path}")
      tf = File.open(filename, "r")
      output = tf.gets(nil)
      tf.close
      File.unlink(filename)
      output
    end
# TBD: not treating arrays in hash yet
def set_id_ref_mapping!(obj,ret)
  return nil unless obj.kind_of?(Hash)
  obj.each_value{|v|
    next unless v.kind_of?(Hash)
    set_id_ref_mapping!(v,ret)
    next unless v["id"] and v["link"]
    next unless v["link"]["href"] and v["link"]["rel"] == "self"
    if v["link"]["href"] =~ %r{^http.+[/]list(.+$)}
      ret[v["id"]] = $1
    end
  }
end

def ret_id_ref_mapping(obj)
  ret = {}
  set_id_ref_mapping!(obj,ret)
  ret
end

# TBD: bug in this code inthat gets confused by columns that are "json attributes"
def ret_replaced_ids_with_refs(obj,top_is_factory=true,id_ref_mapping=nil)
  id_ref_mapping ||= ret_id_ref_mapping(obj) 
  ret = {}
  return ret unless obj.kind_of?(Hash)
  obj.each{|k,v|
    if k == "link" or k == "id"
      next
    elsif v.kind_of?(Hash) 
      reformated_v = ret_replaced_ids_with_refs(v,!top_is_factory,id_ref_mapping)
      ret[k] = reformated_v unless reformated_v.empty?
    elsif top_is_factory
      next
    elsif v.kind_of?(Array)
      ret[k] = v
    else    
    # if get here v is a scalar
      if k =~ %r{^.+_id$}
         ret["*"+k] = id_ref_mapping[v] if id_ref_mapping[v]
      else
         ret[k] = v unless v.nil?
      end
    end
  }
  ret
end



json_data = RestClient.get("http://localhost:7000/list/library/#{library_name}.json?depth=deep")

mapped_hash = ret_replaced_ids_with_refs(JSON.parse(json_data).to_hash)
mapped_json = JSON.pretty_generate(mapped_hash)

modified_json = edit_data(mapped_json)
