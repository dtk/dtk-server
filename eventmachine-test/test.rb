require 'rubygems'
require 'eventmachine'
require 'pp'
module StompClient
  include EM::Protocols::Stomp

   def connection_completed
     connect :login => 'mcollective', :passcode => 'marionette'
   end

   def receive_msg msg
     if msg.command == "CONNECTED"
       subscribe "/topic/mcollective.discovery.reply"
     else
       decoded_msg = Marshal.load(msg.body)#Security.decodemsg(msg.body)
       decoded_msg[:body] = Marshal.load(decoded_msg[:body])
       pp ['got a message', decoded_msg]
     end
   end
 end

 EM.run{
   EM.connect 'localhost', 6163, StompClient
 }

