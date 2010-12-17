#!/usr/bin/ruby
require 'rubygems'
require 'mcollective'
include MCollective::RPC
  
mc = rpcclient("chef_client")
msg_content = {:run_list => ["recipe[ser_account]"]}
printrpc mc.run(msg_content)
 
printrpcstats
 
mc.disconnect
