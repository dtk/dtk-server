module XYZ
  #TODO: move all dynamic loading to use these helper classes
  class DynamicLoader
    def self.load_and_return_adapter_class(adapter_type,adapter_name)
      begin
        Lock.synchronize{r8_nested_require("#{adapter_type}/adapters",adapter_name)}
        XYZ.const_get "#{cap_form(adapter_type)}#{cap_form(adapter_name)}"
       rescue LoadError
        raise Error.new("cannot find #{adapter_type} adapter (#{adapter_name})")
      end
    end
   private
    Lock = Mutex.new
    def self.cap_form(x)
      x.to_s.split("_").map{|t|t.capitalize}.join("")
    end
  end
end
