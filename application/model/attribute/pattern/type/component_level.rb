module DTK; class Attribute
  class Pattern; class Type
    class ComponentLevel < self
      include CommonNodeComponentLevel

      def type()
        :component_level
      end

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
        if ndx_nodes.empty?
          if opts[:create]
            raise ErrorUsage.new("Node name (#{pattern_node_name()}) in attribute does not match an existing node")
          end
          return ret 
        end

        cmp_fragment = pattern_component_fragment()
        ndx_cmps = ret_matching_components(ndx_nodes.values,cmp_fragment).inject(Hash.new){|h,r|h.merge(r[:id] => r)}
        if ndx_cmps.empty?
          if opts[:create]
            raise ErrorUsage.new("Component name (#{pattern_component_name()}) in attribute does not match an existing component in node (#{pattern_node_name()})")
          end
          return ret 
        end
        
        attr_fragment = pattern_attribute_fragment()
        attrs = ret_matching_attributes(:component,ndx_cmps.values.map{|r|r.id_handle()},attr_fragment)
        if attrs.empty? and opts[:create]
          @created = true
          attrs = create_attributes(ndx_cmps.values)
        end
        @attribute_stacks = attrs.map do |attr|
          cmp = ndx_cmps[attr[:component_component_id]]
          {
            :attribute => attr,
            :component => cmp,
            :node => ndx_nodes[cmp[:node_node_id]]
          }
        end 
        ret
      end
     private
      def create_attributes(components)
        ret = Array.new
        attribute_idhs = Array.new
        field_def = {'display_name' => pattern_attribute_name()}
        components.each do |cmp|
          attribute_idhs += cmp.create_or_modify_field_def(field_def)
        end
        return ret if attribute_idhs.empty?
        #TODO: can make more efficient by having create_or_modify_field_def return object with cols
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:component_component_id],
          :filter => [:oneof,:id,attribute_idhs.map{|idh|idh.get_id()}]
        }
        attr_mh = attribute_idhs.first.createMH()
        Model.get_objs(attr_mh,sp_hash)
      end

      def pattern_node_name()
        pattern() =~ NodeComponentRegexp 
        $1
      end
      def pattern_component_fragment()
        pattern() =~ NodeComponentRegexp
        $2
      end
      def pattern_attribute_fragment()
        pattern() =~ AttrRegexp
        $1
      end

      def pattern_component_name()
        first_name_in_fragment(pattern_component_fragment())
      end
      def pattern_attribute_name()
        first_name_in_fragment(pattern_attribute_fragment())
      end

      def first_name_in_fragment(fragment)
        fragment =~ NameInFragmentRegexp
        $1
      end
      NodeComponentRegexp = /^node<([^>]*)>\/(component.+$)/
      AttrRegexp = /^node[^\/]*\/component[^\/]*\/(attribute.+$)/ 
      NameInFragmentRegexp = /[^<]*<([^>]*)>/
    end
  end; end
end; end

