#TODO: initially scafolds SemanticType then wil replace
#TODO: initially form sap from sap config then move to model where datatype has dynamic attribute that gets filled in
module XYZ
  module AttributeDatatypeInstanceMixin
    def ret_datatype()
      st_summary = self[:semantic_type_summary]
      return self[:data_type] unless st_summary
      is_array? ? "array(#{st_summary})" : st_summary
    end
    def self.ret_datatypes()
    end

    def ret_default_info()
      default = self[:value_asserted]
      return nil unless default
      #TODO: temparily unraveling arrays
      if is_array?()
        ret = Hash.new
        hash_semantic_type = semantic_type[:array]
        default.each_with_index do |d,i|
          el = ret_default_info__hash(hash_semantic_type,d)
          el.each{|k,v|ret.merge!("#{k}[#{i.to_s}]" => v)}
        end
        ret
      else
        ret_default_info__hash(semantic_type,default)
      end
    end

   private

    def ret_default_info__hash(hash_semantic_type,default)
      hash_semantic_type.inject({}) do |h,(k,v)|
        if v[:dynamic]
          h
        else
          info = Hash.new
          info.merge!(:required=> v[:required]) if v.has_key?(:required)
          info.merge!(:type => v[:type])
          info.merge!(:default_value => default[k]) if default.has_key?(k)
          h.merge(k => info)
        end
      end
    end

    def semantic_type()
      @semantic_type ||= SemanticTypeSchema.create_from_attribute(self)
    end
    def is_array?()
      semantic_type().is_array?
    end
  end
end
