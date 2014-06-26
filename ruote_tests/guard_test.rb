require 'rubygems'
require 'ruote'
require 'pp'
# require 'ruote/storage/hash_storage'

class MyRemoteParticipant
  include Ruote::LocalParticipant
 
  def consume(workitem)
    pp "enterring #{workitem.params["label"]}"
    label = workitem.params["label"]
    workitem.fields["label"] = label
    if label == 3
      sleep 5
    else
      sleep 2
    end
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
    participant :remote, :label => 1
    concurrence :merge_type => :stack do
        participant :remote, :label => 2
        participant :remote, :label => 3
        participant :remote, :label => 4
      sequence do
        concurrence do
          listen :to => 'remote', :where => '${label} == 3', :upon => "reply"
          listen :to => 'remote', :where => '${label} == 2', :upon => "reply"
        end
        participant :remote, :label => 5
      end
    end
    participant :report
  end
end


wfid = engine.launch(pdef)
engine.wait_for(wfid)
