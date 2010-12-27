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
require 'ruote'
require 'ruote/storage/fs_storage'

# preparing the engine

engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::FsStorage.new('ruote_work')))

# registering participants

engine.register_participant :chef_client do |workitem|
  mc = rpcclient("chef_client",:options => options)
  msg_content = {:run_list => ["recipe[user_account]"]}
  results =  mc.run(msg_content)
  data = results.map{|result|result.results[:data]} #.first.results[:data]}
  mc.disconnect
  pp [:data,data]
  workitem.fields['message'] = data 
end

engine.register_participant :bravo do |workitem|
  pp [:bravo,workitem.fields]
end

  # defining a process
=begin
  pdef = Ruote.process_definition :name => 'test' do
    sequence do
      participant :alpha
      participant :alpha2
      participant :bravo
    end
  end
=end
=begin
pdef = Ruote.process_definition :name => 'test' do
  concurrence do
    sequence do
      participant :alpha2
      after
    end
    sequence do
      participant :alpha
      after
    end
  end
  define 'after' do
    participant :bravo
  end
end
=end
pdef = Ruote.process_definition :name => 'test' do
  sequence do
    participant :chef_client
    participant :chef_client
    participant :bravo
  end
end
  # launching, creating a process instance

  wfid = engine.launch(pdef)

  engine.wait_for(wfid)
    # blocks current thread until our process instance terminates

  # => 'I received a message from Alice'

