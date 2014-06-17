#!/usr/bin/env ruby
require 'rubygems'
require 'json'
require 'restclient'
require 'chef/client'
require 'pp'
# Monker patch from rightlink
EXCLUDED_OHAI_PLUGINS = [ 'linux::block_device' ]

# Not for the feint of hearts:
# We need to disable the linux block device plugin because it can cause
# deadlocks (see description of LinuxBlockDevice below).
# So monkey patch Ohai to add the concept of excluded plugins and add
# the linux block device plugin to the excluded list.
# require 'ohai'
module Ohai
  class System
    alias :require_all_plugins :require_plugin
    def require_plugin(plugin_name, force=false)
      unless EXCLUDED_OHAI_PLUGINS.include?(plugin_name)
        require_all_plugins(plugin_name, force)
      end
    end
  end
end


# TBD: below is just temp until make into gems
root = File.expand_path('../../', File.dirname(__FILE__)) + "/"
SYSTEM_DIR = root + 'system/'

require root + 'utils/utils'
XYZ::Config.process_config_file("/etc/reactor8/client.conf")

require SYSTEM_DIR + 'messaging'
msg_bus_server = XYZ::Config[:msg_bus_server] || "localhost"

# TBD: move to be on server side or in client library
module XYZ
  class ClientNode
  end
  class ChefClientNode < ClientNode
    class << self
      def convert_execute_on_content_to_chef_form(msg_content)
        hash_ret = {}
        recipe_name = msg_content[:external_cmp_ref]
        attr_vals = msg_content[:attribute_values]
        next if recipe_name.nil? or  attr_vals.nil?
        cmp_ref = if recipe_name =~ %r{^(.+)::} 
          $1
        else
          recipe_name
        end

        attr_ret = ret_chef_cmp_attrs_from_msg_content(attr_vals)
        hash_ret[cmp_ref] = 
          {:recipe => recipe_name,
           :attributes => attr_ret}
        hash_ret
      end
     private
      def ret_chef_cmp_attrs_from_msg_content(attr_vals)
        ret = {}
        attr_vals.each_value do |attr_val|
          attr_name = attr_val[:external_attr_ref]
          value = attr_val[:value]
          next if attr_name.nil? or value.nil?
	  set_chef_attr_and_value!(ret,attr_name,value)
        end
        ret
      end
      # if attr_name of form x/y and value is v then returns {x => {y => z}}
      def set_chef_attr_and_value!(ret,chef_attr_name,v)
        set_chef_attr_and_value_aux!(ret,chef_attr_name.split("/"),v)
      end
      def set_chef_attr_and_value_aux!(ret,attr_name_array,v)
        first = attr_name_array[0]
        if attr_name_array.size == 1
           ret[first] = v
        else
           ret[first] ||= {}
	   set_chef_attr_and_value_aux!(ret[first],attr_name_array[1..attr_name_array.size-1],v)
        end
      end

    # TBD: deprecate below
    public
      def convert_rest_call_form_to_chef_form(hash_data)
        return {} if hash_data["component"].nil?
        hash_ret = {}
        hash_data["component"].each{|cmp_ref,cmp_info|
          recipe_name = cmp_info["external_cmp_ref"]
          attr_info_hash = cmp_info["attribute"]
          next if recipe_name.nil? or  attr_info_hash.nil?
          attr_ret = ret_chef_cmp_attrs_from_rest_call(attr_info_hash)
          hash_ret[cmp_ref] = 
             {:recipe => recipe_name,
              :attributes => attr_ret}
        }
        hash_ret
      end
     private
      def ret_chef_cmp_attrs_from_rest_call(attr_info_hash)
        ret = {}
        attr_info_hash.each_value{|attr_info|
          attr_name = attr_info["external_attr_ref"]
          value = attr_info["value"]
          next if attr_name.nil? or value.nil?
	  set_chef_attr_and_value!(ret,attr_name,value)
        }
        ret
      end
    end
  end
end
Chef::Config[:solo] = true
Chef::Config[:file_cache_path] =  "/tmp/chef-solo"
Chef::Config[:cookbook_path] = "/root/Reactor8/our_app_installation_cookbooks"
# Chef::Config[:log_level] = :debug
Rest_server = XYZ::Config[:rest_server] || "localhost"
Node = ARGV[0] || "/library/saved/node/pg"

def get_node_guid(node_uri)
  json_node_id = RestClient.get("http://#{Rest_server}:7000/get_guid#{node_uri}.json")
  JSON.parse(json_node_id.to_s)["guid"] 
end

def run_recipes(chef_attrs_hash)
  chef_attrs_hash.each_value{|x|
    attrs = x[:attributes].merge("recipes" => [x[:recipe]])
    chef_solo = Chef::Client.new()
    Chef::Log.level = Chef::Config[:log_level] 
    chef_solo.json_attribs = attrs 
    chef_solo.run_solo
 }
end

# print "http://#{Rest_server}:7000/list_node_attributes#{Node}.json\n"

def run_chef_solo(msg_content)
=begin
deprecated
 json_data = RestClient.get("http://#{Rest_server}:7000/list_node_attributes#{Node}.json")

  # print json_data.to_s << "\n" 
  hash_data = JSON.parse(json_data.to_s)

  chef_attrs_hash = XYZ::ChefClientNode.convert_rest_call_form_to_chef_form(hash_data)
=end
  chef_attrs_hash = XYZ::ChefClientNode.convert_execute_on_content_to_chef_form(msg_content)
  print JSON.pretty_generate(chef_attrs_hash) << "\n"
  run_recipes(chef_attrs_hash)
  :succeeded
end


node_id = get_node_guid(Node)
print "node_id = #{node_id.inspect}\n" 
node_key = XYZ::MessageBusMsgOut.key(node_id,:node)
node_queue = "node-"+node_id.to_s

XYZ::R8EventLoop.start(:host => msg_bus_server) do
    msg_bus_client = XYZ::MessageBusClient.new()
    node_queue = msg_bus_client.subscribe_queue(node_key,:auto_delete => true)
    node_queue.subscribe do |trans_info,msg_bus_msg_in|
      pp [:received,trans_info,msg_bus_msg_in]
      if trans_info[:reply_to]
        proc_msg_in = XYZ::ProcessorMsg.new(msg_bus_msg_in.parse())
        work = proc_msg_in.msg_type == :execute_on_node ? proc{run_chef_solo(proc_msg_in.msg_content)} : proc{}
        task = XYZ::WorkerTaskLocal.new proc_msg_in, :work => work
        task.add_reply_to_info(trans_info[:reply_to], msg_bus_client)
        task.execute()
      else
       raise Error.new("expected reply to")
      end
   end
end




