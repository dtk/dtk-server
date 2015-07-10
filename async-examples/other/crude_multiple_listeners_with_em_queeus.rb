require 'rubygems'
require 'ramaze'
require 'eventmachine'
Queues = {}

class DeferrableBody
  include EventMachine::Deferrable

  def send(data)
    @body_callback.call data
  end

  def each(&blk)
    @body_callback = blk
  end
end

# TODO: this needs to detect when listen connection is killed so it can delete that version of the queue
# may be impossible; so woudl need control and bearer channels
class MyController < Ramaze::Controller
  map '/'

  def listen
    body = DeferrableBody.new
    Queues[self] = q = EM::Queue.new
    # Get the headers out there asap, let the client know we're alive...
    EM.next_tick do
      request.env['async.callback'].call [200, { 'Content-Type' => 'text/plain' }, body]
    end
    q_pop_proc = proc{
      q.pop do |msg|
        if msg == 'end'
          Queues.delete(self)
          body.succeed
        else
          body.send("#{msg}\n")
          q_pop_proc.call
        end
      end
    }
    q_pop_proc.call
    throw :async
  end

  def send
    msg = request['msg']
    Queues.each_value { |q| q.push(msg) }
    nil
  end
end

Ramaze::Log.level = Logger::WARN
Ramaze.start(adapter: :thin, port: 3000, file: __FILE__)
