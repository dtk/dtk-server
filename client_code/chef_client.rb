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
  Response = {}
  def initialize(msg_id)
    super()
    @msg_id = msg_id
  end
  def report()
    response = {:node_name => node.name}
    if success?()
      response.merge!(:status => :success)
    else
      error_info = {
        :status => :failed,
        :error => {
          :backtrace =>  Array(backtrace),
          :formatted_exception => run_status.formatted_exception
        }
      }
      response.merge!(error_info)
    end
    TestHandler::Response[@msg_id] = response
  end
end

module MCollective
  module Agent
    class Chef_client < RPC::Agent
      # Basic echo server
      def run_action
        validate :msg, String
        run_recipe(request.uniqid)
        handler_response = TestHandler::Response.delete(request.uniqid)
        reply.data = handler_response
      end
    end
  end
end






