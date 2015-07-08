require 'rubygems'
require 'eventmachine'
module XYZ
  module R8EM
    # include EM::Protocols::Stomp
    def self.add_timer(*args,&block)
      ::EM.add_timer(*args,&block)
    end

    def self.start_em_for_passenger?
      if defined?(PhusionPassenger)
        unless reactor_running?()
          Thread.new { EventMachine.run }
          puts "EventMachine has been started!"
        end
      end
    end

    def self.reactor_running?
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

