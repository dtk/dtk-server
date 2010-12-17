#!/usr/bin/ruby
require 'rubygems'
require 'pp'
require 'mcollective'
include MCollective::RPC
  
mc = rpcclient("chef_client")
msg_content = {:run_list => ["recipe[user_account]"]}
results =  mc.run(msg_content)
results.map{|result|pp result.results[:data]} #.first.results[:data]}
 
mc.disconnect
