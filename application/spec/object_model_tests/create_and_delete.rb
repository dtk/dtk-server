#!/usr/bin/env ruby
root = File.expand_path('../../', File.dirname(__FILE__))
require root + '/app'
require 'pp'

#Object.create_from_hash(id_handle,hash,clone_helper=nil,opts={})
#creates in database an object or object with children in it by following the hash structure; id_handle is the pointer to the factory object in teh appropriate parent; dont worry about clone_helper (which is something I will better hide). opts is passed but largely not used;
module XYZ
  parent_uri = ARGV[0] || "/project/p1/node"
  parent_id_handle = IDHandle[:c => 2, :uri => parent_uri]
  hash = {"new" =>
    {:type=>"instance",
    :node_interface=>
      {"eth0"=>
        {:type=>"ethernet",
          :address=>"10.249.187.33",
          :display_name=>"eth0"}
      }
    }
  }
  #create_object
  Object.create_from_hash(parent_id_handle,hash)

  #retrieve and print what was put in db
  id_handle = IDHandle[:c => 2, :uri => "#{parent_uri}/new"]
  pp [:test_whether_object_exists, Object.exists?(id_handle)]
 
  opts = Hash.new
  opts[:no_hrefs] = true
  opts[:depth] = :deep
  opts[:no_null_cols] = true

  pp [:stored_object, Object.get_instance_or_factory(id_handle,nil,opts)]

  #delete object
  Object.delete_instance(id_handle)
  pp [:test_whether_object_exists, Object.exists?(id_handle)]
end


