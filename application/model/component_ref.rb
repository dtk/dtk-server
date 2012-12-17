module DTK 
  class ComponentRef < Model
    #looks at both the component template attribute value plus the overrides
    #indexed by compoennt ref id
    #we assume each component ref has component template id set
    def self.get_ndx_attribute_values(cmp_refs)
      ret = Hash.new
      return ret if cmp_refs.empty?
      
      #get template attribute values
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:attribute_value,:component_component_id],
        :filter => [:oneof,:component_component_id,cmp_refs.map{|r|r[:component_template_id]}]
      }
      attr_mh = cmp_refs.first.model_handle(:attribute)
      ndx_template_to_ref = cmp_refs.inject(Hash.new){|h,cmp_ref|h.merge(cmp_ref[:component_template_id] => cmp_ref[:id])}

      ndx_attrs = get_objs(attr_mh,sp_hash).inject(Hash.new) do |h,attr|
        cmp_ref_id = ndx_template_to_ref[attr[:component_component_id]]
        h.merge(attr[:id] => attr.merge(:component_ref_id => cmp_ref_id))
      end

      #get override attributes
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:attribute_value,:attribute_template_id],
        :filter => [:oneof,:component_ref_id,cmp_refs.map{|r|r[:id]}]
      }
      override_attr_mh = attr_mh.createMH(:attribute_override)
      get_objs(override_attr_mh,sp_hash) do |ovr_attr|
        attr = ndx_attrs[ovr_attr[:attribute_template_id]]
        if ovr_attr[:attribute_value]
          attr[:attribute_value] = ovr_attr[:attribute_value]
        end
      end
      
      ndx_attrs.each_value do |attr|
        cmp_ref_id = attr[:component_ref_id]
        (ret[cmp_ref_id] ||= Array.new) << attr
      end
      ret
    end
  end
end
