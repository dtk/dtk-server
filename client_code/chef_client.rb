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
#          :backtrace =>  Array(backtrace),
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
            metadata    :name        => "run chef actions",
                        :description => "Agent to initiate Chef runs",
                        :author      => "Reactor8",
                        :license     => "",
                        :version     => "",
                        :url         => "",
                        :timeout     => 300

      def run_action
        validate :run_list, :list
        validate :attributes, :list
        begin
          run_recipe(request.uniqid,request[:run_list],request[:attributes])
        rescue
        end
        handler_response = RunHandler::Response.delete(request.uniqid)
        reply.data = handler_response
      end
     private
      def run_recipe(id,run_list,attributes)
        pp [:run_list,run_list]
        pp [:attributes,attributes]
        chef_client = Chef::Application::Client.new
        chef_client.reconfigure
        handler = RunHandler.new(id)
        Chef::Config[:report_handlers] << handler
        Chef::Config[:exception_handlers] << handler

        chef_client.setup_application
        hash_attribs = (attributes||{}).merge({"run_list" => run_list||[]})
        Chef::Client.new(hash_attribs).run
      end
    end
  end
end


################Monkey patch to get functionality to replace arrays
# returns [to_remove,to_add]
def remove_replace_markers(hash)
  #TODO: just looking for {"recipe1" => {"!replace:foo" => [..]},"recipe2=> ..}
  #e.g., {"user_account"=>{"list"=>[{"gid"=>nil, "username"=>"usertom", "uid"=>nil}]}}
  return [{},source_hash] unless hash.kind_of?(Hash)
  to_remove = Hash.new
  to_add = Hash.new
  hash.each do |k,v|
    if v.kind_of?(Hash) and v.size == 1 and v.keys.first =~ /^!replace:(.+)$/
      attr_name = $1
      to_remove[k] = "!merge:#{attr_name}"
      to_add[k] = {attr_name => v.values.first}
    else
      to_add[k] = v
    end
  end
  [to_remove,to_add]
end



class Chef
  class Node
    def expand!
      # This call should only be called on a chef-client run.
      expansion = run_list.expand('server')
      raise Chef::Exceptions::MissingRole if expansion.errors?

      Chef::Log.debug("Applying attributes from json file")

      ############## patch replacing
      ## @normal_attrs = Chef::Mixin::DeepMerge.merge(@normal_attrs, @json_attrib_for_expansion)
      to_remove,to_add = remove_replace_markers(@json_attrib_for_expansion)
      @normal_attrs = 
        if to_remove.empty? 
          Chef::Mixin::DeepMerge.merge(@normal_attrs, @json_attrib_for_expansion)
        else
          with_remove = Chef::Mixin::DeepMerge.merge(@normal_attrs,to_remove)
          Chef::Mixin::DeepMerge.merge(with_remove,to_add)
        end
      ########### end of patch

      self[:tags] = Array.new unless attribute?(:tags)
      @default_attrs = Chef::Mixin::DeepMerge.merge(default_attrs, expansion.default_attrs)
      @override_attrs = Chef::Mixin::DeepMerge.merge(override_attrs, expansion.override_attrs)

      @automatic_attrs[:recipes] = expansion.recipes
      @automatic_attrs[:roles] = expansion.roles

      expansion.recipes
    end
  end
end



