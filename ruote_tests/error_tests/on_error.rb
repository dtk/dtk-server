require 'rubygems'
require 'ruote'
require 'pp'
require 'rubygems'
require 'ruote'
STDOUT.sync = true
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

class ErrorHandlerParticipant
  include Ruote::LocalParticipant

  def consume(workitem)
puts "error handler"
# pp Engine.process(Wfid)
error = workitem.error
pp [error.class,error]
    reply_to_engine(workitem)
  end
end

Engine = Ruote::Dashboard.new(Ruote::Worker.new(Ruote::HashStorage.new))

Engine.register_participant 'bad', ErrorParticipant
Engine.register_participant 'alpha', DefaultParticipant
Engine.register_participant 'beta', DefaultParticipant
Engine.register_participant 'gamma', DefaultParticipant
Engine.register_participant 'error_handler', ErrorHandlerParticipant
# Engine.register do
#  catchall DefaultParticipant
# end

pdef = Ruote.process_definition do
  concurrence do
    sequence do
      sequence do
        alpha
       participant 'bad', on_error: 'error_handler'
      end
      beta
    end
    gamma
  end
end
Wfid = Engine.launch(pdef)
Engine.wait_for(Wfid)
