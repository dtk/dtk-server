module XYZ
  class HashObject < Hash
    def initialize(initial_val=nil,convert_initial=false,&block)
      block ? super(&block) : super()
      if initial_val
        replace(convert_initial ? convert_nested_hashes(initial_val) : initial_val)
      end
    end

    def object_slice(slice_keys,opts={})
      self.class.object_slice(self,slice_keys,opts)
    end
    #auto vivification trick from http://t-a-w.blogspot.com/2006/07/autovivification-in-ruby.html
    def self.create_with_auto_vivification()
      self.new{|h,k| h[k] = self.new(&h.default_proc)}
    end

    def []=(k,v)
      super(k.to_s,v)
    end
    def has_key?(k)
      super(k.to_s)
    end
    def [](k)
      frozen? ? (super(k.to_s) if has_key?(k)) : super(k.to_s)
    end
    def freeze()
      self.each_value{|x|x.freeze}
      super
    end

    def is_complete?()
      false
    end
    def do_not_extend()
      false
    end
   private
    #coverts hashes that are not a HashObject or a child of HashObject
    def convert_nested_hashes(obj)
      if obj.kind_of?(HashObject)
        obj #no encoding needed
      elsif obj.kind_of?(Hash)
        ret = self.class.new()
        obj.each{|k,v| ret[k] = convert_nested_hashes(v)}
        ret
      elsif obj.kind_of?(Array)
        ret = ArrayObject.new
        obj.each{|v|ret << convert_nested_hashes(v)}
        ret
      else
        obj        
      end
    end

   public
    class << self
      def [](x)
        new(x)
      end

      def object_slice(hash,slice_keys,opts={})
        ret = {}
        slice_keys.each{|k| ret[k] = hash[k] if (hash[k] or opts[:include_null_cols])}
        ret
      end

      #TBD: might better related nested and auto vivfication
      #TBD: consider instaed just using
      #class NilClass
      #  def [](x)
      #    nil
      #  end
      #end
      def nested_value(hash,path)
        return hash if path.empty?
        nested_value_private(hash,path.dup)
      end
     private
      # "*" in path means just take whatever is next (assuming singleton; otehrwise takes first
      def nested_value_private(hash,path)
        return nil unless hash.kind_of?(Hash)
        f = path.shift
        f = hash.keys.first if f == "*"
        return nil unless hash.has_key?(f.to_s)
        return hash[f] if path.length == 0
        nested_value_private(hash[f],path)
      end
    end
  end
  #Used as input to data source normalizer
  class DataSourceUpdateHash < HashObject  
    #for efficiency not initializing @completeness_info = nil
    def constraints()
      @completeness_info ? @completeness_info.constraints : nil
    end

    def is_complete?()
      @completeness_info ? @completeness_info.is_complete? : nil
    end    

    def mark_as_complete(constraints={})
      if constraints.empty?
        @completeness_info ||= HashIsComplete.new()
      else
        @completeness_info = HashIsComplete.new(constraints)
      end
      self
    end

    def set_constraints(constraints)
      @completeness_info = HashIsComplete.new(constraints)
      self
    end
  end 

  class HashCompletnessInfo
    def is_complete?()
      false
    end
    def constraints()
      nil
    end
  end
  class HashMayNotBeComplete < HashCompletnessInfo
  end
  class HashIsComplete < HashCompletnessInfo
    def initialize(constraints={})
      @constraints = constraints
    end
    def is_complete?()
      true
    end
    def constraints()
      @constraints
    end
  end

  #Used as input to db update from hash 
  class DBUpdateHash < DataSourceUpdateHash
    #for efficiency not initializing @do_not_extend = false
    def do_not_extend()
      @do_not_extend ? true : false
    end
  end
end


