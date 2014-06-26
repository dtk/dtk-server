#!/usr/bin/env ruby
require 'rubygems'
require 'tmpdir'
require 'json'
require 'restclient'
require 'pp'

root = File.expand_path('../../', File.dirname(__FILE__))
require root + '/utils/internal/helper/config.rb'
XYZ::Config.process_config_file("/etc/reactor8/worker.conf")
require root + '../app'
msg_bus_server = XYZ::Config[:msg_bus_server] || "localhost"

container = ARGV[0] || "/library/saved"

def edit_data(json_data)
      filename = "reactor-"
      0.upto(20) { filename += rand(9).to_s }
      filename << ".js"
      filename = File.join(Dir.tmpdir, filename)
      tf = File.open(filename, "w")
      tf.sync = true
      tf.puts json_data
      tf.close
      raise "Please set EDITOR environment variable" unless system("#{ENV["EDITOR"] || "vi"} #{tf.path}")
      tf = File.open(filename, "r")
      output = tf.gets(nil)
      tf.close
      File.unlink(filename)
      output
 end

def ret_modified_values(hash)
  ret = []
  hash.each{|k,v|
  case k
    when "node","component":
      v.each_value{|x| ret.concat(ret_modified_values(x))}
    when "attribute":
      v.each{|attr,attr_val|
        if attr_val["value"]
	  ret << {:id => attr_val["id"], :value => attr_val["value"]}
        end
      }
  end
  }
  ret
end

json_data = RestClient.get("http://localhost:7000/list_contained_attributes#{container}.json?value_type=asserted")


# TBD: moidfied is a misnomer
modified_json = edit_data(json_data)
modified_hash = JSON.parse(modified_json).to_hash
modified_values = ret_modified_values(modified_hash)
exit if modified_values.nil?
exit if modified_values.empty?
print modified_values.inspect << "\n"

# TBD: put in the server
XYZ::R8EventLoop.start(:host => msg_bus_server) do
    msg_bus_client = XYZ::MessageBusClient.new()
    modified_values.each{|x|
      id = x[:id].to_s
      msg_content = XYZ::Aux.convert_to_symbol_form_aux(x[:value])
      proc_msg = XYZ::ProcessorMsg.create(
        {:msg_type => :asserted_value,:msg_content=> msg_content,:target_object_id => id})
      exchange = msg_bus_client.exchange(proc_msg.topic(),:type => :topic)
      msg_bus_msg_out = proc_msg.marshal_to_message_bus_msg()
      exchange.publish_with_callback(msg_bus_msg_out,:key => proc_msg.key()) do |trans_info,msg_bus_msg_in|
#        pp [:received_from, msg_bus_msg_in,trans_info]
        pp trans_info[:task].flatten if trans_info[:task]
        
      end
     }
end






