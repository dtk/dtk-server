require 'rubygems'
require 'mcollective'
require 'eventmachine'
require 'pp'
require '/root/R8Server/utils/internal/hash_object'
require '/root/R8Server/utils/internal/eventmachine_helper'
require 'mcollective_multiplexer'
EM.run do
  handler = XYZ::CommandAndControlAdapter::MCollectiveMultiplexer.instance
  callbacks = {
    :on_msg_received => proc{|msg|pp [:received,msg]},
    :on_timeout => proc{pp :timeout} 
  }
  context = {:callbacks => callbacks, :expected_count => 1, :timeout => 5}
  handler.sendreq_with_callback("ping","discovery",context)
end
