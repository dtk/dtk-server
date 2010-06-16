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
    def is_complete?()
      false
    end
    def donot_extend()
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
      # "*" in path means just take whatever is next (assuming singleton; otehrwise takes first
      def nested_value_private(hash,path)
        return nil unless hash.kind_of?(Hash)
        f = path.shift
        f = hash.keys.first if f == "*"
        return nil unless hash.has_key?(f)
        return hash[f] if path.length == 0
        nested_value_private(hash[f],path)
      end
    end
  end
  #Used as input to db update from hash 
  #TBD: put in DSUpdateHash which same but does not have donot extend
  class DBUpdateHash < HashObject
    attr_reader :constraints, :donot_extend
    def initialize(initial_val=nil,convert_initial=false,&block)
      super
      #if non null means when update done then delete all with respect to parent meeting constraints
      #no contraints captured by {} 
      @constraints = nil
      @donot_extend = false
    end

    def is_complete?()
      @constraints ? true : nil
    end    

    def mark_as_complete(constraints=nil)
      if constraints
        @constraints = constraints
      else 
        @constraints ||= {}
      end
      self
    end
    def set_constraints(constraints)
      @constraints = constraints
      self
    end
  end 
end


