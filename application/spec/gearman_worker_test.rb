#!/usr/bin/env ruby
require 'rubygems'
require 'gearman'
root = File.expand_path('../', File.dirname(__FILE__))
require root + '/app'

Gearman::Util.debug = true
servers = '10.5.5.9:4730'

worker = Gearman::Worker.new(servers.split(','), 'example')

worker.add_ability('import_chef_recipes') do |payload,job|
  print "got request to import_chef_recipe with payload=#{payload.inspect} and job=#{job.inspect}\n"
  begin
    hash_payload = JSON.parse(payload)
    object = eval hash_payload["object"]
    params_x = hash_payload["params"]
    # TBD: hack; not right
    params = params_x.map{|p|
      if p["class"] == "Hash"
        h = {}
        p["val"].each_pair{|k,v| h[k.to_sym] = v}
        h
      elsif p["class"] == "XYZ::IDHandle"
        h = {}
        p["val"].each_pair{|k,v| h[k.to_sym] = v}
        XYZ::IDHandle.new(h)
      else
        p["val"]
      end
    }
    method = hash_payload["method"].to_sym
    task = XYZ::Task.new(hash_payload["task"]["c"],hash_payload["task"]["uri"]) 
    print "object = #{object.inspect}; method = #{method}; params = #{params.inspect}; task={task.inspect}\n" 
    # TBD: need to handle case where opts already in params
    params << {:task => task}
    object.send(method,*params)
    task.update_status(:complete) 
    true
   rescue Exception => err
    task.add_error_toplevel(err) if err.kind_of?(XYZ::Error)
    task.update_status(:error)
    false
  end
end

loop { worker.work }


