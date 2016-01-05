require 'rubygems'
require 'eventmachine'
module XYZ
  module R8EM
    # include EM::Protocols::Stomp
    def self.add_timer(*args, &block)
      ::EM.add_timer(*args, &block)
    end

    def self.start_em_for_passenger?
      if defined?(PhusionPassenger)
        unless reactor_running?()
          Thread.new { EventMachine.run }
          Log.info 'EventMachine has been started! Waiting for it to be ready ...'

          sleep(1) until reactor_running?()
          Log.info 'EventMachine is ready!'

        end
      end
    end

    def self.connect(*args)
      start_em_for_passenger?
      ::EM.connect(*args)
    end

    def self.reactor_running?
      ::EM.reactor_running?()
    end
    def self.cancel_timer(timer_or_sig)
      ::EM.cancel_timer(timer_or_sig)
    end
    def self.add_periodic_timer(*args, &block)
      ::EM.add_periodic_timer(*args, &block)
    end
  end
end
