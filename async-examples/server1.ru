require 'rubygems'
require 'ramaze'
class DeferrableBody
  include EventMachine::Deferrable

  def send(data)
    @body_callback.call data
  end

  def each(&blk)
    @body_callback = blk
  end
end

class MyController < Ramaze::Controller
  map '/'

  def index

    body = DeferrableBody.new

    # Get the headers out there asap, let the client know we're alive...
    EM.next_tick do
      request.env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, body]
    end
    #emulate pieces of work being completed
    EM.add_timer(1) do
      body.send "first part\n"
    end
    EM.add_timer(5) do
      body.send "second part\n"
      body.succeed
    end
    EM.add_timer(5) do
      body.send "second part\n"
      body.succeed
    end
    throw :async
  end
end
Ramaze::Log.level = Logger::WARN

Ramaze.start(:root => __DIR__, :started => true)
run Ramaze
