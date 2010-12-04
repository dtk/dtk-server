#!/usr/bin/env ruby
require 'pp'
class ProcessAttributeStrings
  attr_reader :attrs
  def initialize()
    @attrs = Hash.new()
  end
  def attribute(name,vals)
    sn = name.split("/")
    return unless sn.size > 1 and vals[:display_name]
    string_symbol = "#{sn[0]}__#{sn[1,sn.size-1].join("_")}".to_sym
    @attrs[string_symbol] = vals[:display_name]
  end
  def require(*args)
  end
  def method_missing(*args)
  end
  def from_file(filename)
    if File.exists?(filename) && File.readable?(filename)
      self.instance_eval(IO.read(filename), filename, 1)
    else
      raise IOError, "Cannot open or read #{filename}!"
    end
  end
end
file_name = ARGV[0]
class Chef
  Config = {}
end
x=ProcessAttributeStrings.new()
x.from_file(file_name)
pp x.attrs










