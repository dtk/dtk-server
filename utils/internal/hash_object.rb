module XYZ
  class HashObject < Hash
    def initialize(initial_val=nil,convert_initial=false,&block)
      block ? super(&block) : super()
      if initial_val
        replace(convert_initial ? convert_nested_hashes(initial_val) : initial_val)
      end
    end

    def object_slice(slice_keys)
      self.class.object_slice(self,slice_keys)
    end
    def is_comprehensive?()
      false
    end
   private
    #coverts hashes that are not a HashObject or a child of HashObject
    def convert_nested_hashes(hash)
      return hash if hash.kind_of?(HashObject)
      ret = self.class.new()
      hash.each{|k,v| ret[k] = (v.kind_of?(Hash) and not v.kind_of?(HashObject)) ? convert_nested_hashes(v) : v}
      ret  
    end
   public
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
    attr_reader :constraints
    def initialize(initial_val=nil,convert_initial=false,&block)
      super
      #if non null means when update done then delete all with respect to parent meeting constraints
      #no contrainst captured by {} 
      @constraints = nil
    end
    def is_comprehensive?()
      @constraints ? true : nil
    end    
    def mark_as_comprehensive()
      @constraints ||= {}
      self
    end
    def set_constraints(constraints)
      @constraints = constraints
      self
    end
  end 
end


