module DTK
  # TODO: move all dynamic loading to use these helper classes
  class DynamicLoader
    def self.load_and_return_adapter_class(adapter_type,adapter_name,opts={})
      begin
        caller_dir = caller.first.gsub(/\/[^\/]+$/,"")
        Lock.synchronize{r8_nested_require_with_caller_dir(caller_dir,"#{adapter_type}/adapters",adapter_name)}
        type_part = convert?(adapter_type,:adapter_type,opts)
        name_part = convert?(adapter_name,:adapter_name,opts)
        base_class = opts[:base_class]||DTK
        if opts[:subclass_adapter_name]
          base_class.const_get(type_part).const_get name_part
        else
          base_class.const_get "#{type_part}#{name_part}"
        end
       rescue LoadError
        raise Error.new("cannot find #{adapter_type} adapter (#{adapter_name})")
      end
    end

    private

    Lock = Mutex.new
    def self.convert?(n,type,opts)
      (opts[:class_name]||{})[type] || cap_form(n)
    end

    def self.cap_form(x)
      x.to_s.split("_").map{|t|t.capitalize}.join("")
    end
  end
end
