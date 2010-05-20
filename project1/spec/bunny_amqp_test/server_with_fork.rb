#!/usr/bin/env ruby

require '/root/Reactor8/top/utils/utils'
require '/root/Reactor8/top/system/messaging'

require 'pp'
queue_names = ARGV[0] ? ARGV : ['foo']
Q = {}
Signal.trap('INT') { Q[:queue].delete if Q[:queue]; XYZ::R8EventLoop.graceful_stop("stopped")}
Signal.trap('TERM'){ Q[:queue].delete if Q[:queue]; XYZ::R8EventLoop.graceful_stop("stopped")}

XYZ::R8EventLoop.start  do #:host => "172.22.101.115" do #:logging => true do
  queue_names.each do |queue_name|
  XYZ::R8EventLoop.fork(1) do
      client = XYZ::MessageBusClient.new()
      Q[:queue] = client.subscribe_queue(queue_name,:auto_delete=>true)
      Q[:queue].subscribe() do |trans_info,msg_bus_msg_in|
      pp [:recieved, trans_info,msg_bus_msg_in]
      if trans_info[:reply_to]
        begin
           reply_queue = client.publish_queue(trans_info[:reply_to],:passive => true)
          sleep(2)
	  msg_bus_msg = XYZ::ProcessorMsg.create(:msg_type => :task).marshal_to_message_bus_msg()
          task = XYZ::WorkerTaskLocal.new("success on queue #{queue_name}",:completed)
          reply_queue.publish(msg_bus_msg, :message_id => trans_info[:reply_to], :task => task)
         rescue Exception => e
           print "exception: #{e}\n"
         end
      end
    end
   end
 end
 pp EM.forks
end
