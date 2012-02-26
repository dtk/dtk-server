module Puppet::Parser::Functions
  newfunction(:hdp_default, :type => :rvalue) do |args|
    args = [args].flatten(1)
    var_name = args[0]
    default = args[1]
    val = lookupvar("::#{var_name}")||:undefined
    ["",:undefined].include?(val) ? (default||"") : val
  end
end


