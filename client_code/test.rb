#!/usr/bin/ruby
require 'rubygems'
require 'pp'
require 'mcollective'
include MCollective::RPC
options = {
  :disctimeout=>2, 
  :config=>"/etc/mcollective/client.cfg",
  :filter=>{"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}, 
  :timeout=>500000000 
}
  
mc = rpcclient("chef_client",:options => options)
msg_content = {:run_list => ["recipe[user_account]"]}
results =  mc.run(msg_content)
results.map{|result|pp result.results[:data]} #.first.results[:data]}
 
mc.disconnect
