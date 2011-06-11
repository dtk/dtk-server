#!/usr/bin/env ruby
root = File.expand_path('../', File.dirname(__FILE__))
require 'pp'
require root + '/app'
sp_hash = {:cols => [:repo,:branch]}
c =2 
impl_mh = XYZ::ModelHandle.new(c,:implementation)
impls = XYZ::Model.get_objects_from_sp_hash(impl_mh,sp_hash)
impls.each do |impl|
  next if impl[:branch] == "master"
  pp "deleting repo #{impl[:repo]} branch #{impl[:branch]}"
  XYZ::Repo.delete(:implementation => impl)
end


