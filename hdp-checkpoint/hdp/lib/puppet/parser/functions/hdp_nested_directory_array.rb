module Puppet::Parser::Functions
   #TODO: was going to use this for recursive createsm but further exploration should issue with multiple resource declarations; remove if not using
  #helper function used in doing a recursive directory create
  newfunction(:hdp_nested_directory_array, :type => :rvalue) do |args|
    args = [args].flatten(1)
    dir_path = args[0]
    ret = Array.new
    parts = dir_path.split("/").reject{|x|x.empty?}
    first = parts.shift
    ret = ["/#{first}"]
    parts.each do |part|
      ret << "#{ret.last}/#{part}"
    end
    ret
  end
end
