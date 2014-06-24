#!/usr/bin/env ruby

require '/root/Reactor8/top/utils/utils'
require '/root/Reactor8/top/system/messaging'

require 'pp'
queue_names = ARGV[0] ? ARGV : ['foo']
Signal.trap('INT') { XYZ::R8EventLoop.graceful_stop("stopped")}
Signal.trap('TERM'){ XYZ::R8EventLoop.graceful_stop("stopped")}

XYZ::R8EventLoop.start  do #:host => "172.22.101.115" do #:logging => true do
  queue_names.each do |queue_name|
    client = XYZ::MessageBusClient.new()
    # TBD: put in catch block
    work_queue = client.subscribe_queue(queue_name,:auto_delete=>true)
    work_queue.subscribe() do |trans_info,msg_bus_msg_in|
      pp [:recieved, trans_info,msg_bus_msg_in]
      work = proc {
        # do work
        sleep(5)
       result = :succeed
        print "finished with result #{result}\n"
        result
      }
      task = XYZ::WorkerTaskLocal.new(msg_bus_msg_in, 
               {:work => work, 
#                :concurrent => true,
                :caller_channel => trans_info[:reply_to], 
                :msg_bus_client => client})
      task.execute()
    end
 end
end
