require 'rubygems'
require 'ruote'
require 'pp'
require 'rubygems'
require 'ruote'

class DefaultParticipant
  include Ruote::LocalParticipant

  def consume(workitem)
    puts "* #{workitem.participant_name}"
    reply_to_engine(workitem)
  end
end

class ErrorParticipant
  include Ruote::LocalParticipant

  def consume(_workitem)
    puts "error"
    raise "Houston, something is wrong"
  end
end

engine = Ruote::Engine.new(Ruote::Worker.new(Ruote::HashStorage.new))

engine.register_participant 'bad', ErrorParticipant
engine.register_participant 'alpha', DefaultParticipant
engine.register_participant 'beta', DefaultParticipant
engine.register_participant 'gamma', DefaultParticipant
# engine.register do
#  catchall DefaultParticipant
# end

pdef = Ruote.process_definition do
  concurrence do
    sequence do
      sequence do
        participant 'bad' #, :on_error => :undo
        alpha
      end
      beta
    end
    gamma
  end
end
wfid = engine.launch(pdef)
engine.wait_for(wfid)
storage = engine.storage
pp engine.storage.find_expressions(wfid)
