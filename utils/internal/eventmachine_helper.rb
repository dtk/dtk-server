require 'rubygems'
require 'eventmachine'
module XYZ
  module R8EM
   # include EM::Protocols::Stomp
    def self.add_timer(*args,&block)
      ::EM.add_timer(*args,&block)
    end
    def self.reactor_running?()
      ::EM.reactor_running?()
    end
    def self.cancel_timer(timer_or_sig)
      ::EM.cancel_timer(timer_or_sig)
    end
    def self.add_periodic_timer(*args,&block)
      ::EM.add_periodic_timer(*args,&block)
    end
  end
end

