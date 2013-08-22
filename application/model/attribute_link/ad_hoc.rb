module DTK
  class AttributeLink
    class AdHoc
      def self.attribute_link_hashes(assembly_idh,target_attr_term,source_attr_term)
        target_attr_idhs = Attribute::Pattern::Assembly.get_attribute_idhs(assembly_idh,target_attr_term)
        if target_attr_idhs.empty?
          raise ErrorUsage.new("No matching attribute to target term (#{target_attr_term})")
        end
        unless source_attr_idh = Attribute::Pattern::Assembly::Source.get_attribute_idh(assembly_idh,source_attr_term)
          raise ErrorUsage.new("No matching attribute to source term (#{source_attr_term})")
        end
        #TODO: need to do more chaecking and processing to include:
        #  if has a relation set already and scalar conditionally reject or replace
        # if has relation set already and array, ...
        source_attr_id = source_attr_idh.get_id()
        assembly_id = assembly_idh.get_id()
        target_attr_idhs.map do |target_attr_idh|
          {
            :assembly_id => assembly_id,
            :input_id => target_attr_idh.get_id(),
            :output_id => source_attr_id
          }
        end
      end
    end
  end
end
