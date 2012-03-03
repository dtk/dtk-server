module Puppet::Parser::Functions
  newfunction(:hdp_array_from_comma_list, :type => :rvalue) do |args|
    args = [args].flatten(1)
    args[0].empty? ? "" : args[0].split(",")
  end
end
