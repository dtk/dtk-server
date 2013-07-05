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

Count = 20
Frequency = 0.5
class MyController < Ramaze::Controller
  map '/'

  def index
    body = DeferrableBody.new
    # Get the headers out there asap, let the client know we're alive...
    EM.next_tick do
      request.env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, body]
    end
    repeat(body,Count)
    puts request.env['REMOTE_ADDR']
    throw :async
  end


  def repeat(body,index)
    #emulate pieces of work being completed
    EM.add_timer(Frequency) do
        puts "YOOYOY"
      body.send "part #{(Count-index).to_s}\n + #{Time.now}"
      puts "YOOYOY"
      EM.next_tick do
        if index == 0
          body.succeed
        else
          repeat(body,index-1)
        end
      end
    end   
  end
end
Ramaze::Log.level = Logger::INFO

Ramaze.start(:root => __DIR__, :started => true)
run Ramaze
