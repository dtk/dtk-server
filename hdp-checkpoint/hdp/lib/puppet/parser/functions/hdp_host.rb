module Puppet::Parser::Functions
  newfunction(:hdp_host, :type => :rvalue) do |args|
    args = [args].flatten(1)
    var = args[0]
    val = lookupvar(var)
    (val.nil? or val == :undefined) ? "" : val #TODO: may instead throw an error if no value
  end
end
