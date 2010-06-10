module XYZ
  class HashObject < Hash
    def initialize(initial_val=nil,&block)
      block ? super(&block) : super()
      replace(initial_val) if initial_val
    end

    def object_slice(slice_keys)
      self.class.object_slice(self,slice_keys)
    end
    class << self
      def [](x)
        new(x)
      end
      #auto vivification trick from http://t-a-w.blogspot.com/2006/07/autovivification-in-ruby.html
      def create_with_auto_vivification()
        self.new{|h,k| h[k] = self.new(&h.default_proc)}
      end

      def object_slice(hash,slice_keys)
        ret = {}
        slice_keys.each{|k| ret[k] = hash[k] if hash[k]}
        ret
      end
      #TBD: might better related nested and auto vivfication
      def nested_value(hash,path)
        nested_value_private(hash,path.dup)
      end
     private
      def nested_value_private(hash,path)
        return nil unless hash.kind_of?(Hash)
        return nil unless hash.has_key?(f = path.shift)
        return hash[f] if path.length == 0
        nested_value_private(hash[f],path)
      end
    end
  end
  #Used as input to db update from hash 
  class DBUpdateHash < HashObject
  end 
  #Used to indicate that the keys of the has (with correspond to refs with a factory parent)
  #are comprehensive meaning that when do an update all non matching refs are deleted
  class DBUpdateCWAHash < DBUpdateHash 
  end 
end
