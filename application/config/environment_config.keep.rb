module R8
  module EnvironmentConfig
    System_Root_Dir = "/root/R8Server"
    Base_Uri = "http://ec2-184-73-175-145.compute-1.amazonaws.com:7000"
    CommandAndControlMode = "mcollective"
    GitExecutable = "/usr/bin/git"
    TestUser = "joe"
  end
  Config = Hash.new unless defined? ::R8::Config
  R8::Config[:command_and_control] ||= Hash.new

  R8::Config[:command_and_control][:node_config] ||= Hash.new
  R8::Config[:command_and_control][:node_config][:type] = "mcollective"
end

