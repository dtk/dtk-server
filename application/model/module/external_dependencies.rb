module DTK
  class ExternalDependencies < Hash
    def initialize(hash={})
      super()
      replace(pruned_hash(hash)) unless hash.empty?
    end
    KeysProblems = [:inconsistent,:possibly_missing,:ambiguous]
    KeysOk = [:component_module_refs]
    KeysAll = KeysProblems+KeysOk

    def any_errors?
      !!KeysProblems.find{|k|has_data?(self[k])}
    end

    def ambiguous?
      self[:ambiguous]
    end

    def possibly_missing?
      self[:possibly_missing]
    end

    def pruned_hash(hash)
      ret = {}
      KeysAll.each do |k|
        v = hash[k]
        ret.merge!(k => v) if has_data?(v)
      end
      ret
    end

    private

    def has_data?(val)
      !val.nil? && (!val.is_a?(Array) || !val.empty?())
    end
  end
end

