#!/usr/bin/env ruby
require 'rubygems'
require 'restclient'
require 'tmpdir'
require 'json'
require 'pp'

require File.expand_path('../app', File.dirname(__FILE__))


container = ARGV[0] || "/library/saved"

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

def ret_modified_values(hash)
  ret = []
  hash.each{|k,v|
  case k
    when "node","component":
      v.each_value{|x| ret.concat(ret_modified_values(x))}
    when "attribute":
      v.each{|attr,attr_val|
        if attr_val["value"]
	  ret << {:id => attr_val["id"], :value => attr_val["value"]}
        end
      }
  end
  }
  ret
end

json_data = RestClient.get("http://127.0.0.1:7000/list_contained_attributes#{container}.json?value_type=asserted")


# TBD: moidfied is a misnomer
modified_json = edit_data(json_data)
modified_hash = JSON.parse(modified_json).to_hash
modified_values = ret_modified_values(modified_hash)
exit if modified_values.nil?
exit if modified_values.empty?
print modified_values.inspect << "\n"
