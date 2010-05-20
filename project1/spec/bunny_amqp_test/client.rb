#!/usr/bin/env ruby
require '/root/Reactor8/top/utils/utils'
require '/root/Reactor8/top/system/messaging'
require 'pp'
queue_names = ARGV[0] ? ARGV : ['foo']
client = nil


XYZ::R8EventLoop.start  do # :logging => true do #:host => "172.22.101.115" do #:logging => true do
  client = XYZ::MessageBusClient.new()
  top_proc_msg = XYZ::ProcessorMsg.create :msg_type => :test_top
  task_set = XYZ::WorkerTask.create(:task_set,top_proc_msg)
  queue_names.each do |queue_name|
    proc_msg = 
      if queue_name == "stop"
        XYZ::ProcessorMsg.create :msg_type => :stop
      else
        XYZ::ProcessorMsg.create :msg_type => :test, :msg_content => "msg to queue #{queue_name}"
    end
    task = XYZ::WorkerTask.create(:remote,proc_msg,
            {:queue_name => queue_name, :passive => true, 
            :msg_bus_client => client,
             :reply_timeout => 30
           })
    task_set.add_task(task)
  end
  task_set.execute()
end


