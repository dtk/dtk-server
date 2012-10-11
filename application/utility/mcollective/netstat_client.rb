#!/usr/bin/env ruby
require 'rubygems'
require 'mcollective'
require 'pp'
include MCollective::RPC
mc = rpcclient("netstat")

pp mc.get_tcp_udp()
mc.disconnect
