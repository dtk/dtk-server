require 'rubygems'
require 'eventmachine'
require 'pp'

module StompClient
  include EM::Protocols::Stomp

  def connection_completed
    connect :login => 'mcollective', :passcode => 'marionette'
    puts "connection established"
  end
end

EM.run {

  conn = EM.connect('localhost', 6163, StompClient)
  EM::add_timer(0) {
    puts "sending"
    conn.send('/topic/mcollective', 'foo')
}

EM::add_timer( 10 ) {
    #
    # send_data(data) takes a well-formed stomp frame!
    #
    conn.send_data("DISCONNECT\n\n\x00")
    puts "EM.run disconnect sent"
    #
    EventMachine::stop_event_loop()
}
}
