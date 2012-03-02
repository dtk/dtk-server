module Puppet::Parser::Functions
  newfunction(:hdp_nagios_target_hosts, :type => :rvalue) do |args|
    args = [args].flatten(1)
    types = args[0].split("'")
    types.map{|t|scope.function_hdp_host(t)}.map{|h|h.empty? ? [] : [h].flatten(1)}.flatten
  end
end
