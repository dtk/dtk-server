module DTK
  class ModuleExternalDeps < Hash
    def initialize(hash={})
      super()
      replace(hash)
    end
    KeysProblems = [:inconsistent,:possibly_missing,:ambiguous]
    # KeysOk = [:ndx_matching_branches]

    def any_errors?()
      !!KeysProblems.find{|k|has_data_under_key?(k)}
    end
    def possible_problems?()
      ret = Array.new
      KeysProblems.each do |k|
        ret << self[k] if has_data_under_key?(k)
      end
      ret unless ret.empty?
    end

    def ambiguous?()
      self[:ambiguous]
    end
    def possibly_missing?()
      self[:possibly_missing]
    end

    def ret_hash_form(opts={})
      ret = Hash.new
      KeysProblems.each do |k|
        ret.merge!(k => self[k]) if has_data_under_key?(k)
      end
      if component_module_refs = opts[:component_module_refs] || component_module_refs?()
        ret.merge!(:component_module_refs => component_module_refs)
      end
      ret
    end
   private
    def has_data_under_key?(key)
      val = self[key]
      !val.nil? and !val.kind_of?(Array) or !val.empty?()
    end

    def component_module_refs?()
      ret = nil
      unless ndx_matching_branches = self[:ndx_matching_branches]
        return ret
        end
      ndx_ret = ndx_matching_branches.values.inject(Hash.new) do |h,r|
        h.merge(r.id() => r)
      end
      unless ndx_ret.empty?
        ComponentModuleRef.create_from_module_branches?(ndx_ret.values)
      end
    end
  end              
end; end
