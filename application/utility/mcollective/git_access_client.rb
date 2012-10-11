#!/usr/bin/env ruby
require 'rubygems'
require File.expand_path('../../require_first', File.dirname(__FILE__))
r8_require_common_lib('auxiliary')
require 'mcollective'
require 'tempfile'
require 'pp'

include MCollective::RPC
class Params
  class << self
    require 'sshkey'
    def ret_params()
      server_public_key = File.open("/root/.ssh/id_rsa.pub").read
      new_key =  ::SSHKey.generate(:type => "rsa")
      agent_public_key = new_key.ssh_public_key
      agent_private_key = new_key.private_key
      File.open("/tmp/git_access_client_key","w"){|f| f << agent_private_key}
      File.open("/tmp/git_access_client_key_pub","w"){|f| f << agent_public_key}
      {
        :agent_ssh_key_public => agent_public_key,
        :agent_ssh_key_private => agent_private_key,
        :server_ssh_key_public => server_public_key,
        :server_hostname => ::DTK::Common::Aux.get_ec2_public_dns()
      }
    end
  end
end
mc = rpcclient("git_access")

pp mc.add_rsa_info(Params.ret_params())
mc.disconnect
