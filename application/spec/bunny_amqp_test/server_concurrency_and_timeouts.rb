#!/usr/bin/env ruby

require '/root/Reactor8/top/utils/utils'
require '/root/Reactor8/top/system/messaging'

require 'pp'
queue_names = ARGV[0] ? ARGV : ['foo']
Signal.trap('INT') { XYZ::R8EventLoop.graceful_stop("stopped")}
Signal.trap('TERM'){ XYZ::R8EventLoop.graceful_stop("stopped")}

class Work
  include EM::Deferrable
  def initialize(trans_info,msg_bus_msg_in)
    work = proc {
      # TBD: don't think can put in an amqp call here without embedding EM.next_tick
      # do work
      print "started\n"
#      sleep(10)

      15.times{|i|
       print "#{i.to_s}\n"
       sleep(1)
      }

      :succeeded
    }
    callback = proc do |result|
      self.set_deferred_status result,result
      print "result=#{result}\n"
    end
    EM.defer( work, callback )
  end
end

XYZ::R8EventLoop.start  do #:host => "172.22.101.115" do #:logging => true do
  client = XYZ::MessageBusClient.new()
  workers = []
  queue_names.each do |queue_name|
    # TBD: put in catch block
    work_queue = client.subscribe_queue(queue_name,:auto_delete=>true)
    work_queue.subscribe() do |trans_info,msg_bus_msg_in|
      pp [:recieved, trans_info,msg_bus_msg_in]

      work = Work.new(trans_info,msg_bus_msg_in)
      workers << work
      if trans_info[:reply_to]
        work.callback do |result|
          print "finished with result #{result}\n"
          begin
            reply_queue = client.publish_queue(trans_info[:reply_to],:passive => true)
	    msg_bus_msg = XYZ::ProcessorMsg.create(:msg_type => :task).marshal_to_message_bus_msg()
            task = 
              if result == :canceled
                XYZ::WorkerTaskLocal.new("canceled on queue #{queue_name}",:canceled)
              else
                XYZ::WorkerTaskLocal.new("success on queue #{queue_name}",:completed)
              end
            reply_queue.publish(msg_bus_msg, :message_id => trans_info[:reply_to], :task => task)
           rescue Exception => e
             print "exception: #{e}: #{e.backtrace}\n"
          end
        end
      else
         work.callback{|result|"finished with result #{result}; not reply\n"}
      end
    end
  end
  stop_queue = client.subscribe_queue("stop",:auto_delete=>true)
  stop_queue.subscribe() do |trans_info,msg_bus_msg_in|
    pp [:recieved, trans_info,msg_bus_msg_in]
    workers.each{|w|
      w.set_deferred_status :succeeded, :canceled
    }
    if trans_info[:reply_to]
      begin
        reply_queue = client.publish_queue(trans_info[:reply_to],:passive => true)
	msg_bus_msg = XYZ::ProcessorMsg.create(:msg_type => :cancel_ack).marshal_to_message_bus_msg()
        task = XYZ::WorkerTaskLocal.new(:cancel_ack,:completed)
        reply_queue.publish(msg_bus_msg, :message_id => trans_info[:reply_to], :task => task)
       rescue Exception => e
        print "exception: #{e}: #{e.backtrace}\n"
      end
    else
      "finished cancel, which was caleld with no reply ack\n"
    end
  end
end
