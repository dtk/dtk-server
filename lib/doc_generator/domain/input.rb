module DTK; class DocGenerator; class Domain
  class Input < ::Hash
    def initialize(hash = {})
      super()
      replace(hash) unless hash.empty?
    end

    def scalar(key)
      value?(key)
    end

    # if value is a hash then just return values part
    def array(key)
      ret = []
      return ret unless obj = value?(key)

      if obj.kind_of?(Array)
        ret = obj.map { |el| self.class.new(el) }
      elsif obj.kind_of?(Hash)
        ret = obj.values.map { |el| self.class.new(el) }
      end
      ret
    end
    
    private

    def value?(key)
     if has_key?(key.to_s)
       self[key.to_s]
     elsif has_key?(key.to_sym)
       self[key.to_sym]
     end
    end
  end
end; end; end

