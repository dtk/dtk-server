require 'puppet'
require 'rspec-system/spec_helper'
require 'rspec-system-puppet/helpers'
require 'rspec-system-serverspec/helpers'

include RSpecSystemPuppet::Helpers
include Serverspec::Helper::RSpecSystem

RSpec.configure do |c|
  # Enable color in Jenkins
  c.tty = true

  c.before(:each) do
    Puppet::Util::Log.level = :warning
    Puppet::Util::Log.newdestination(:console)
  end

  c.before :suite do
    #Install puppet
    puppet_install

    forge_module_install({ "stahnma/epel" => "0.0.3", "puppetlabs/stdlib" => "3.2.0" })
    puppet_module_install source: proj_dir, module_name: 'rvm'
  end

  c.before(:each) do
    # delete all non required modules installed in specs
    excludes = ["rvm", "epel", "stdlib"].map{|m| " -not -iname #{m} "}.join
    shell("find /etc/puppet/modules/ -maxdepth 1 -mindepth 1 -type d #{excludes} -exec rm -rf {} \\;").exit_code.should be_zero
  end
end

def fixture_rcp(src, dest)
  rcp sp: "#{proj_dir}/spec/fixtures/#{src}", dp: dest
end

def proj_dir
  File.absolute_path File.join File.dirname(__FILE__), '..'
end

def forge_module_install(modules)
  modules.each do |mod, version|
    shell("test -d /etc/puppet/modules/#{mod.split('/')[1]} || puppet module install #{mod} -v #{version}").exit_code.should be_zero
  end
end
