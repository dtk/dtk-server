require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe file('/etc/motd') do
  it { should be_file }
end

describe file('/etc/motd2') do
  it { should be_file }
end
