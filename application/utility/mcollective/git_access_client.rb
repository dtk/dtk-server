#!/usr/bin/env ruby
require 'rubygems'
require 'pp'

require 'mcollective'

require 'tempfile'
include MCollective::RPC
class Params
  class << self
    require 'sshkey'
    def ret_params()
      ret = Hash.new
      k =  ::SSHKey.generate(:type => "rsa")
      {
        :agent_ssh_key_public => k.public_key,
        :agent_ssh_key_private => k.private_key
        #ret[:server_ssh_key_public]
        #ret[:server_hostname]
      }
    end
  end
end
mc = rpcclient("git_access")

pp mc.add_rsa_info(Params.ret_params())
mc.disconnect
