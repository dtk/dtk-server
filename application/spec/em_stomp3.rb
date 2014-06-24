
# from https://github.com/gmallard/stomp-demo/blob/master/em/sendsub/sendsub.rb
require 'rubygems'
require 'eventmachine'
require 'pp'

module StompClientForSend
  include EM::Protocols::Stomp

  def initializa()
    @connected = false
    @needs_send = true
  end

  def connected?
    @connected
  end

  def disconnect_and_stop(conn)
    conn.send_data("DISCONNECT\n\n\x00")
    EventMachine::stop_event_loop()
  end


  def connection_completed
    connect :login => 'mcollective', :passcode => 'marionette'
    puts "connection established"
    @connected = true
  end

  # Send some messages only once.
  #
  def send_message_once(conn, dest, message, headers={})
    return if not @needs_send
    unless conn.connected?
      puts "not connecetd yet; will retry"
    end
    puts "sending msg"
    conn.send(dest, outmsg, headers) # EM supplied Stomp method
    @needs_send = false
  end
end

EM.run {

  conn = EM.connect('localhost', 6163, StompClientForSend)
  EM::add_periodic_timer( 1 ) {
    conn.send_message_once(conn,'/topic/mcollective', 'foo')
  }
  
  EM::add_timer(5 ) {
    conn.disconnect_and_stop(conn)
  }
}
