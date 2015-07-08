module DTK
  class HierarchicalTags < Hash
    def self.reify(obj)
      unless obj.nil?
        obj.is_a?(HierarchicalTags) ? obj : new(obj)
      end
    end
    def initialize(obj)
      super()
      replace_hash =
        if obj.is_a?(String)
          {obj.to_sym => nil}
        elsif obj.is_a?(Hash)
          obj.inject({}){|h,(k,v)|h.merge(k.to_sym => v.is_a?(Hash) ? self.new(v) : v)}
        elsif obj.is_a?(Array) && !obj.find{|el|!el.is_a?(String)}
          obj.inject({}){|h,k|h.merge(k.to_sym => nil)}
        else
          raise Error.new("Illegal input to form hierarchical hash (#{obj.inspect})")
        end
      replace(replace_hash)
    end

    def base_tags?
      ret = keys
      ret unless ret.empty?
    end

    def nested_tag_value?(base_tag)
      base_tag = normalize_key(base_tag)
      has_tag?(base_tag) && self[base_tag]
    end

    def has_tag?(base_tag)
      base_tag = normalize_key(base_tag)
      key?(base_tag)
    end

    private

     def normalize_base_tag(base_tag)
       base_tag.to_sym
     end
  end
end
