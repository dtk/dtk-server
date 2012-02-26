module Puppet::Parser::Functions
  newfunction(:hdp_template_var, :type => :rvalue) do |args|
    args = [args].flatten(1)
    qualified_var = args[0]
    unless qualified_var =~ /^::/
      #module_name = lookupvar("module_name")||"UNKNOWN"
      #qualified_var = "::#{module_name}::params::#{args[0]}"
      component = lookupvar("component")||"UNKNOWN"
      qualified_var = "::hdp-#{component}::params::#{args[0]}"
    end
    val = lookupvar(qualified_var)
    (val.nil? or val == :undefined) ? "" : val #TODO: may instead throw an error if no value
  end
end
