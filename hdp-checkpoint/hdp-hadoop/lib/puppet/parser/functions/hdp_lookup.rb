module Puppet::Parser::Functions
  newfunction(:hdp_lookup, :type => :rvalue) do |args|
    var_name = args[0]
    default = args[1]
    
    #looks for braibale value in following order
    #1) Sees if variable is globally defined #TODO: stub for things like external lookup
    #2) Looks at if theer is a default
    #3) last resort is returning empty string
    val = lookupvar("::#{var_name}")
    ["",:undefined].include?(val) ? (default||"") : val
  end
end


