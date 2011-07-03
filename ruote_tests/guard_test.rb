require 'rubygems'
require 'ruote'
require 'pp'
#require 'ruote/storage/hash_storage'

class MyRemoteParticipant
  include Ruote::LocalParticipant
 
  def consume(workitem)
    pp "enterring #{workitem.params["label"]}"
    workitem.fields["label"] = workitem.params["label"]
    sleep 2
    pp "leaving #{workitem.params["label"]}"
   reply_to_engine(workitem)
  end
 end
 
engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))
 
engine.register_participant :remote, MyRemoteParticipant

engine.register_participant :report do |workitem|
  pp [:fields,workitem.fields]
end

engine.register_participant :start do |workitem|
  pp :start
end
 
pdef = Ruote.process_definition :name => 'test' do
  sequence do
    participant :start
    concurrence :merge_type => :mix do
      sequence do
        participant :remote, :label => 1
        participant :remote, :label => 2
      end
      sequence do
        listen :to => 'remote', :where => '${label} == 2', :upon => "reply"
        participant :remote, :label => 3
      end
    end
    participant :report
  end
end


wfid = engine.launch(pdef)
engine.wait_for(wfid)
