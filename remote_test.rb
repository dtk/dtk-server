require 'rubygems'
require 'ruote'
require 'pp'
#require 'ruote/storage/hash_storage'

class WorkQueue
  Queue = Array.new
  Sema = Mutex.new
  def self.push(msg)
    pp [:pushing_msg]
    Sema.synchronize{Queue << msg}
  end

  def self.pop()
    loop do 
      sleep 3
      msg = nil
      Sema.synchronize{msg = Queue.shift}
      return msg if msg
    end
  end
end

class MyRemoteParticipant
  #include Ruote::LocalParticipant
 
  def consume(workitem)
pp :here
    WorkQueue.push(workitem_to_msg(workitem))
  end
 
  def on_reply(workitem)
    workitem.fields['msg'] = "back at #{Time.now.to_s}"
  end
 
  protected
 
  def workitem_to_msg(workitem)
    workitem
  end
end
 
class Receiver < Ruote::Receiver
  attr_reader :thread
  def initialize(engine)
    super
    @thread = Thread.new { listen }
  end
 
  protected
 
  def listen
     loop do  
      pp :in_loop
      sleep 2
     reply_to_engine(workitem_from_msg(WorkQueue.pop))
    end
  end
 
  def workitem_from_msg(msg)
    msg
  end
end
 
engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))
 
engine.register_participant :remote, MyRemoteParticipant

engine.register_participant :report do |workitem|
  pp "I received a message #{workitem.fields['msg']}"
end

engine.register_participant :start do |workitem|
  pp :start
end
 
receiver = Receiver.new(engine)
pdef = Ruote.process_definition :name => 'test' do
  sequence do
    participant :start
    participant :remote
    participant :report
  end
end


wfid = engine.launch(pdef)
#receiver.thread.join
engine.wait_for(wfid)
