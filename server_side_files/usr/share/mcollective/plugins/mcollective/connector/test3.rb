require 'rubygems'
require 'mcollective'
require 'eventmachine'
require 'pp'
require 'mcollective'

BlankFilter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
Options = {
        :disctimeout=>3,
        :config=>"/root/R8Server/utils/internal/command_and_control/adapters/node_config/mcollective/client.cfg",
        :filter=> BlankFilter,
        :timeout=>120
}

require 'mcollective'
######## Monkey patches for version 1.2 
module MCollective
  class Config
    attr_writer :connector
  end

  class Client
    def initialize(configfile)
      @config = Config.instance
      @config.loadconfig(configfile) unless @config.configured

      #R8Change
      pp @config.connector
      @config.connector = "stomp_eventmachine"
      pp @config.connector
      #END R8Change
  
      @connection = PluginManager["connector_plugin"]
      @security = PluginManager["security_plugin"]

      @security.initiated_by = :client
      @options = nil
      @subscriptions = {}

      @connection.connect
    end
  end
end

include MCollective::RPC
rpc_client = rpcclient("discovery",:options => Options)
