require 'rubygems'
require 'mcollective'
require 'eventmachine'
require 'pp'
require '/root/R8Server/utils/internal/hash_object'
require 'mcollective_multiplexer'
EM.run do
  handler = XYZ::CommandAndControlAdapter::MCollectiveMultiplexer.instance
  callbacks = {
    :on_msg_received => proc{|msg|pp [:received,msg]},
    :on_timeout => proc{pp :timeout} 
  }
  context = {:callbacks => callbacks}
  handler.sendreq_with_callback("ping","discovery",context)
end
