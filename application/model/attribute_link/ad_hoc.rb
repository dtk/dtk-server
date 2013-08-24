module DTK
  class AttributeLink
    class AdHoc
      def self.attribute_link_hashes(assembly_idh,target_attr_term,source_attr_term)
        target_attr_idhs = Attribute::Pattern::Assembly.get_attribute_idhs(assembly_idh,target_attr_term)
        if target_attr_idhs.empty?
          raise ErrorUsage.new("No matching attribute to target term (#{target_attr_term})")
        end
        source_attr_idh,fn = Attribute::Pattern::Assembly::Source.get_attribute_idh_and_fn(assembly_idh,source_attr_term)
        unless source_attr_idh
          raise ErrorUsage.new("No matching attribute to source term (#{source_attr_term})")
        end
        #TODO: need to do more chaecking and processing to include:
        #  if has a relation set already and scalar conditionally reject or replace
        # if has relation set already and array, ...
        attr_info = {
          :assembly_id =>  assembly_idh.get_id(),
          :output_id => source_attr_idh.get_id()
        }
        attr_info.mergd!(:function => fn) if fn

        target_attr_idhs.map{|target_attr_idh|attr_info.merge(:input_id => target_attr_idh.get_id())}
      end
    end
  end
end

