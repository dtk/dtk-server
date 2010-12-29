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
4.times do |j|
  pp [:thhreads, Thread.list]
  arr = []
  results = []

  2.times do |i|
    arr[i] = Thread.new do
      msg_content = {:run_list => ["recipe[user_account]"]}
      results << mc.run(msg_content)
    end
  end

  arr.each {|t| t.join}
  pp [:results, results]
end
mc.disconnect
