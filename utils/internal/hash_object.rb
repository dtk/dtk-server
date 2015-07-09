# TODO: This needed to be simplified and cleaned up
module DTK
  class HashObject < ::Hash
    r8_nested_require('hash_object','model')
    r8_nested_require('hash_object','auto_viv')

    def initialize(initial_val=nil,convert_initial=false,&block)
      block ? super(&block) : super()
      if initial_val
        replace(convert_initial ? convert_nested_hashes(initial_val) : initial_val)
      end
    end

    def slice(*slice_keys)
      slice_keys.inject(HashObject.new()) do |h,k|
        if k.is_a?(Hash)
          source_key = k.keys.first
          target_key = k.values.first
          self.key?(source_key) ? h.merge(target_key => self[source_key]) : h
        else
          self.key?(k) ? h.merge(k => self[k]) : h
        end
      end
    end

    def set?(k,v)
      self[k] = v unless key?(k)
    end

    def is_complete?
      false
    end

    def do_not_extend
      false
    end

    private

    # converts hashes that are not a HashObject or a child of HashObject
    def convert_nested_hashes(obj)
      if obj.is_a?(HashObject)
        obj #no encoding needed
      elsif obj.is_a?(Hash)
        ret = self.class.new()
        obj.each{|k,v| ret[k] = convert_nested_hashes(v)}
        ret
      elsif obj.is_a?(Array)
        ret = ArrayClass().new
        obj.each{|v|ret << convert_nested_hashes(v)}
        ret
      else
        obj
      end
    end

    def ArrayClass
      ::Array
    end
  end

  class SimpleHashObject < ::Hash
    def initialize(initial_val=nil,&block)
      block ? super(&block) : super()
      replace(initial_val) if initial_val
    end
  end

  simple_ordered_hash_parent =
    if RUBY_VERSION =~ /^1\.9/ then ::Hash
    else
      require 'active_support/ordered_hash'
      ::ActiveSupport::OrderedHash
    end

  class SimpleOrderedHash < simple_ordered_hash_parent
    def initialize(elements=[])
      super()
      elements = [elements] unless elements.is_a?(Array)
      elements.each{|el|self[el.keys.first] = el.values.first}
    end

    # set unless value is nill
    def set_unless_nil(k,v)
      self[k] = v unless v.nil?
    end

    def set?(*kv_array)
      kv_array.each do |kv|
        k = kv.keys.first
        v = kv.values.first
        set_unless_nil(k,v)
      end
      self
    end
  end

  class PrettyPrintHash < SimpleOrderedHash
    # field with '?' suffix means optioanlly add depending on whether name present and non-null in source
    # if block is given then apply to source[name] rather than returning just source[name]
    def add(model_object,*keys,&block)
      keys.each do |key|
        # if marked as optional skip if not present
        if key.to_s =~ /(^.+)\?$/
          key = $1.to_sym
          next unless model_object[key]
        end
        # special treatment of :id
        val = (key == :id ? model_object.id : model_object[key])
        self[key] = (block ? block.call(val) : val)
      end
      self
    end

    def slice(*keys)
      keys.inject(self.class.new){|h,k|h.merge(k => self[k])}
    end
  end

  require 'tsort'
  class TSortHash < ::Hash
    # defining tsort on this
    include TSort
    def initialize(initial_val=nil)
      super()
      replace(initial_val) if initial_val
    end
    alias_method :tsort_each_node, :each_key
    def tsort_each_child(node, &block)
      fetch(node).each(&block)
    end
  end

  # Used as input to data source normalizer
  class DataSourceUpdateHash < HashObject::AutoViv
    # for efficiency not initializing @completeness_info = nil
    def constraints
      @completeness_info ? @completeness_info.constraints : nil
    end

    def is_complete?
      @completeness_info ? @completeness_info.is_complete? : nil
    end

    # TODO: may want to make :apply_recursively = true be the default
    def mark_as_complete(constraints={},opts={})
      if constraints.empty?
        @completeness_info ||= HashIsComplete.new()
      else
        @completeness_info = HashIsComplete.new(constraints)
      end
      @apply_recursively = opts[:apply_recursively]
      self
    end

    def apply_recursively?
      @apply_recursively
    end

    def set_constraints(constraints)
      @completeness_info = HashIsComplete.new(constraints)
      self
    end
  end

  class HashCompletnessInfo
    def is_complete?
      false
    end

    def constraints
      nil
    end
  end
  class HashMayNotBeComplete < HashCompletnessInfo
  end
  class HashIsComplete < HashCompletnessInfo
    def initialize(constraints={})
      @constraints = constraints
    end

    def is_complete?
      true
    end

    def constraints
      @constraints
    end
  end

  # Used as input to db update from hash
  class DBUpdateHash < DataSourceUpdateHash
    # for efficiency not initializing @do_not_extend = false
    def do_not_extend
      @do_not_extend ? true : false
    end
  end
end

unless RUBY_VERSION =~ /^1\.9/ then ::Hash
  require 'active_support/ordered_hash'
  # monkey patch
  module ActiveSupport
    class OrderedHash < ::Hash
      def pretty_print(q)
        #      q.group(0, "#<OrderedHash", "}>") {
        q.group(0,'','}') do
          #        q.breakable " "
          q.text '{'
          q.group(1) do
            q.seplist(self) do|pair|
              q.pp pair.first
              q.text '=>'
              q.pp pair.last
            end
          end
        end
      end
    end
  end
end
