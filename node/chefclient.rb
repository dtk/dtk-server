#!/usr/bin/env ruby
require 'rubygems'
require 'chef/application/client'
require 'chef/client'
require 'chef/handler'
require 'pp'

def run_recipe(id)
  chef_client = Chef::Application::Client.new
  chef_client.reconfigure
  handler = TestHandler.new(id)
  Chef::Config[:report_handlers] << handler
  Chef::Config[:exception_handlers] << handler

  chef_client.setup_application
#   chef_client.run_application
  json_attribs = nil
  Chef::Client.new(json_attribs).run
end

class TestHandler < Chef::Handler
  Info = {}
  def initialize(msg_id)
    super()
    @msg_id = msg_id
  end
  def report()
    # The Node is available as +node+
    subject = "node name #{node.name}\n"
    require 'pp'; pp [:node_name_in_handler, subject]
    TestHandler::Info[@msg_id] = subject
    # +run_status+ is a value object with all of the run status data
    message = "#{run_status.formatted_exception}\n"
    # Join the backtrace lines. Coerce to an array just in case.
    message << Array(backtrace).join("\n")
  end
end

def run_recipe2()
  chef_client = Chef::Client.new()
  Chef::Log.level = Chef::Config[:log_level]
#  chef_client.json_attribs = attrs
  chef_client.run
end



module MCollective
  module Agent
    class Chefclient < RPC::Agent
      # Basic echo server
      def run_action
        validate :msg, String
        run_recipe(request.uniqid)
        handler_response = TestHandler::Info.delete(request.uniqid)
        reply.data = request[:msg] + " " + handler_response
      end
    end
  end
end






