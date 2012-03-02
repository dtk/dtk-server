module Puppet::Parser::Functions
  newfunction(:hdp_host, :type => :rvalue) do |args|
    args = [args].flatten(1)
    var = args[0]
    val = lookupvar(var)
    (val.nil? or val == :undefined) ? "" : val 
  end
end
