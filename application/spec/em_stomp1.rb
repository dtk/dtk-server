require 'rubygems'
require 'eventmachine'
module StompClient
   include EM::Protocols::Stomp

   def connection_completed
     connect :login => 'mcollective', :passcode => 'marionette'
   end

   def receive_msg msg
     if msg.command == "CONNECTED"
       subscribe '/topic/mcollective'
     else
       p ['got a message', msg]
       puts msg.body
     end
   end
 end

 EM.run{
   EM.connect 'localhost', 6163, StompClient
 }
