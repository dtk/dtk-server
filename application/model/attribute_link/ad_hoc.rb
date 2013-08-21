module DTK
  class AttributeLink
    class AdHoc
      def self.attribute_link_hashes(assembly_idh,target_attr_term,source_attr_term)
        target_attr_idhs = Attribute::Pattern::Assembly.get_attribute_idhs(assembly_idh,target_attr_term)
      end
    end
  end
end
