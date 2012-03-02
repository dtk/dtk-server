module Puppet::Parser::Functions
  newfunction(:hdp_user, :type => :rvalue) do |args|
    args = [args].flatten(1)
    user = args[0]
    val = lookupvar("::hdp::params::#{user}")
    (val.nil? or val == :undefined) ? "" : val 
  end
end
