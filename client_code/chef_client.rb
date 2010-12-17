#!/usr/bin/env ruby
require 'rubygems'
require 'chef/application/client'
require 'chef/client'
require 'chef/handler'
require 'pp'

class RunHandler < Chef::Handler
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
    RunHandler::Response[@msg_id] = response
  end
end

module MCollective
  module Agent
    class Chef_client < RPC::Agent
      # Basic echo server
      def run_action
        validate :run_list, :list
        run_recipe(request.uniqid,request[:run_list])
        handler_response = RunHandler::Response.delete(request.uniqid)
        reply.data = handler_response
      end
     private
      def run_recipe(id,run_list)
        pp [:run_list,run_list]
        chef_client = Chef::Application::Client.new
        chef_client.reconfigure
        handler = RunHandler.new(id)
        Chef::Config[:report_handlers] << handler
        Chef::Config[:exception_handlers] << handler

        chef_client.setup_application
        hash_attribs = {"run_list" => run_list||[]}
        Chef::Client.new(hash_attribs).run
      end
    end
  end
end






