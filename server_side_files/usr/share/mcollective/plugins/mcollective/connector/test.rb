require 'rubygems'
require 'mcollective'
require 'eventmachine'
require 'pp'
module MCollective
  module Connector
    class Base
      def self.inherited(klass)
        # added :single_instance => false
        PluginManager << {:type => "connector_plugin", :class => klass.to_s}
      end
    end
  end
end
require 'stomp_eventmachine'
EventMachine::run {
  connection = MCollective::PluginManager["connector_plugin"]
  connection.connect
  EM.add_timer(1) {
    pp [:outside,connection]
    connection.subscribe("/topic/mcollective.discovery.reply")
  }
}

  
