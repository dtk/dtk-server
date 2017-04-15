#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'eventmachine'
module DTKDebug
  def self.pp(*args)
    ::DTK::Log.debug_pp(['DTKDebug:', args]) 
  end
end

module DTK
  module EventMachineHelper
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
