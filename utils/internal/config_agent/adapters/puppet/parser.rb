require 'rubygems'
require 'pp'
require 'puppet'
=begin
require "puppet/application/parser"

command_line = 
#<Puppet::Util::CommandLine:0xb72e1758
 @args=["validate", "master.pp"],
 @argv=["parser", "validate", "master.pp"],
 @stdin=#<IO:0xb75de578>,
 @subcommand_name="parser",
 @zero="/usr/bin/puppet">


app = Puppet::Application::Parser.new(command_line)
app.run
=end
file = ARGV[0]
file = "/root/r8server-repo/puppet-mysql/manifests/classes/master.pp"
Puppet[:manifest] = file
environment = "production"
krt = Puppet::Node::Environment.new(environment).known_resource_types
pp krt
