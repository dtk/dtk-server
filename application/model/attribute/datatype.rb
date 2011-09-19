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
      self[:value_asserted]
    end
   private
    def semantic_type()
      @semantic_type ||= SemanticTypeSchema.create_from_attribute(self)
    end
    def is_array?()
      semantic_type().is_array?
    end
  end
end
