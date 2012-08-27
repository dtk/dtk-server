#TODO: change HashObject so taht it does not have extra overhead of checking if frozen and then introduce variant that deals with frozen for config vars
module XYZ
  #NOTE: either extend or put in another object that handles virtual attributes but not autovivication to be used in most places
  class SimpleHashObject < Hash
    def initialize(initial_val=nil,&block)
      block ? super(&block) : super()
      if initial_val
        replace(initial_val)
      end
    end
  end

  require 'active_support/ordered_hash'
  class SimpleOrderedHash < ::ActiveSupport::OrderedHash
    def initialize(elements=[])
      super()
      elements = [elements] unless elements.kind_of?(Array)
      elements.each{|el|self[el.keys.first] = el.values.first}
    end
    
    #set unless value is nill
    def set_unless_nil(k,v)
      self[k] = v unless v.nil?
    end
  end

  class PrettyPrintHash < SimpleOrderedHash
    #field with '?' suffix means optioanlly add depending on whether name present and non-null in source
    #if block is given then apply to source[name] rather than returning just source[name]
    def add(model_object,*keys,&block)
      keys.each do |key|
        #if marked as optional skip if not present
        if key.to_s =~ /(^.+)\?$/
          key = $1.to_sym
          next unless model_object[key]
        end
        #special treatment of :id
        val = (key == :id ? model_object.id : model_object[key]) 
        self[key] = (block ? block.call(val) : val)
      end
      self
    end

    def slice(*keys)
      keys.inject(self.class.new){|h,k|h.merge(k => self[k])}
    end
  end

  class HashObject < Hash
    def initialize(initial_val=nil,convert_initial=false,&block)
      block ? super(&block) : super()
      if initial_val
        replace(convert_initial ? convert_nested_hashes(initial_val) : initial_val)
      end
    end

    #protection if foo[x] called where foo is frozen and x does not exist
    def [](x)
      frozen? ? (super if has_key?(x)) : super
    end

    def recursive_freeze()
      each_value{|el| el.recursive_freeze if el.respond_to?(:recursive_freeze)}
      freeze
    end

    def slice(*slice_keys)
      slice_keys.inject(HashObject.new()) do |h,k|
        if k.kind_of?(Hash)
          source_key = k.keys.first
          target_key = k.values.first
          self.has_key?(source_key) ? h.merge(target_key => self[source_key]) : h
        else
          self.has_key?(k) ? h.merge(k => self[k]) : h
        end
      end
    end

    def nested_value(*path)
      return self if path.empty?
      self.class.nested_value_private!(self,path.dup)
    end

    def is_complete?()
      false
    end
    def do_not_extend()
      false
    end

    def set?(k,v)
      self[k] = v unless has_key?(k)
    end

    class << self
      def [](x)
        new(x)
      end
      #auto vivification trick from http://t-a-w.blogspot.com/2006/07/autovivification-in-ruby.html
      def create_with_auto_vivification()
        self.new{|h,k| h[k] = self.new(&h.default_proc)}
      end

      def nested_value(hash,path)
        return hash if path.empty?
        nested_value_private!(hash,path.dup)
      end
      def has_path?(hash,path)
        return true if path.empty?
        has_path_private!(hash,path.dup)
      end

      def set_nested_value!(hash,path,val)
        if path.size == 0
          #TODO this should be error
        elsif path.size == 1
          hash[path.first] = val
        else
          hash[path.first] ||= Hash.new
          set_nested_value!(hash[path.first],path[1..path.size-1],val)
        end
      end
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

    # "*" in path means just take whatever is next (assuming singleton; otehrwise takes first
    # marked by "!" since it updates the path parameter
    def self.nested_value_private!(hash,path)
      return nil unless hash.kind_of?(Hash)
      f = path.shift
      f = hash.keys.first if f == "*"
      return nil unless hash.has_key?(f)
      return hash[f] if path.length == 0
      nested_value_private!(hash[f],path)
    end
    def self.has_path_private!(hash,path)
      return nil unless hash.kind_of?(Hash)
      f = path.shift
      f = hash.keys.first if f == "*"
      return nil unless hash.has_key?(f)
      return hash.has_key?(f) if path.length == 0
      nested_value_private!(hash[f],path)
    end
  end

  class ConfigHash < HashObject
    #TODO: for putting in hooks to better report on config var access errors
  end

  require 'tsort'
  class TSortHash < Hash
    #defining tsort on this
    include TSort
    def initialize(initial_val)
      super()
      replace(initial_val)
    end
    alias tsort_each_node each_key
    def tsort_each_child(node, &block)
      fetch(node).each(&block)
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

require 'active_support/ordered_hash'
#monkey patch
module ActiveSupport
  class OrderedHash < ::Hash
    def pretty_print(q)
#      q.group(0, "#<OrderedHash", "}>") {
      q.group(0,"","}") {
#        q.breakable " "
        q.text "{"
        q.group(1) {
          q.seplist(self) {|pair|
            q.pp pair.first
            q.text "=>"
            q.pp pair.last
          }
        }
      }
    end
  end
end


