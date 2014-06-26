#!/usr/bin/env ruby

# TBD: temp hard coded
root = '/root/Reactor8/top/'
require root + '/utils/internal/daemon'
require root + '/utils/internal/helper/config'
XYZ::Config.process_config_file("/etc/reactor8/worker.conf")
options = {
    :app_name => "r8worker",
    :dir_mode   => :normal, 
    :multiple   => false,
    :ontop      => false,
    :mode       => :load, 
    :backtrace  => true,
    :monitor    => false,
    :log_output => true
  } 

run_dir = XYZ::Config[:run_dir]
options[:dir] ||=  run_dir

XYZ::R8Daemons.run("#{root}project1/tests/worker.rb", options)
