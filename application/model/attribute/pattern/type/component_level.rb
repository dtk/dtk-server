module DTK; class Attribute
  class Pattern; class Type
    class ComponentLevel < self
      include CommonNodeComponentLevel

      def match_attribute_mapping_endpoint?(am_endpoint)
        am_endpoint[:type] == 'component_attribute' and
          am_endpoint[:component_type] == component_instance()[:component_type] and
          am_endpoint[:attribute_name] == attribute_name()
      end
      
      def am_serialized_form()
        "#{component_instance()[:component_type]}.#{attribute_name()}"
      end
      
      def set_parent_and_attributes!(parent_idh,opts={})
        ret = self
        @attribute_stacks = Array.new
        ndx_nodes  = ret_matching_nodes(parent_idh).inject(Hash.new){|h,r|h.merge(r[:id] => r)}
        return ret if ndx_nodes.empty?
        
        pattern  =~ /^node[^\/]*\/(component.+$)/
        cmp_fragment = $1
        ndx_cmps = ret_matching_components(ndx_nodes.values,cmp_fragment).inject(Hash.new){|h,r|h.merge(r[:id] => r)}
        return ret if ndx_cmps.empty?
        
        cmp_fragment =~ /^component[^\/]*\/(attribute.+$)/  
        attr_fragment = $1
        @attribute_stacks = ret_matching_attributes(:component,ndx_cmps.values.map{|r|r.id_handle()},attr_fragment).map do |attr|
          cmp = ndx_cmps[attr[:component_component_id]]
          {
            :attribute => attr,
            :component => cmp,
            :node => ndx_nodes[cmp[:node_node_id]]
          }
        end 
        ret
      end
    end
  end; end
end; end

