module DTK; class Attribute
  class Pattern 
    class Type
      def initialize(pattern)
        @pattern = pattern
      end
      attr_reader :attribute_idhs

     private
      attr_reader :pattern, :id

      class ExplicitId < self
        def initialize(pattern,parent_obj)
          super(pattern)
          @id = pattern.to_i
          if parent_obj.kind_of?(::DTK::Node)
            raise_error_if_not_node_attr_id(@id,parent_obj)
          elsif parent_obj.kind_of?(::DTK::Assembly)
            raise_error_if_not_assembly_attr_id(@id,parent_obj)
          else
            raise Error.new("Unexpected parent object type (#{parent_obj.class.to_s})")
          end
        end

        def set_parent_and_attribute_idhs!(parent_idh,opts={})
          @attribute_idhs = [parent_idh.createIDH(:model_name => :attribute, :id => id())]
          self
        end
       private
        def raise_error_if_not_node_attr_id(attr_id,node)
          unless node.get_node_and_component_attributes().find{|r|r[:id] == attr_id}
            raise ErrorUsage.new("Illegal attribute id (#{attr_id.to_s}) for node")
          end
        end
        def raise_error_if_not_assembly_attr_id(attr_id,assembly)
          unless assembly.get_attributes_all_levels().find{|r|r[:id] == attr_id}
            raise ErrorUsage.new("Illegal attribute id (#{attr_id.to_s}) for assembly")
          end
        end
      end

      class NodeLevel < self
        def set_parent_and_attribute_idhs!(parent_idh,opts={})
          ret = self
          @node_idhs = ret_matching_node_idhs(parent_idh)
          return ret if @node_idhs.empty?

          pattern =~ /^node[^\/]*\/(attribute.+$)/  
          attr_fragment = attr_name_special_processing($1)
          @attribute_idhs = ret_matching_attribute_idhs(:node,@node_idhs,attr_fragment)
          ret
        end
       private
        def attr_name_special_processing(attr_fragment)
          #TODO: make this obtained from shared logic
          if attr_fragment == Pattern::Term.canonical_form(:attribute,'host_address')
            Pattern::Term.canonical_form(:attribute,'host_addresses_ipv4')
          else
            attr_fragment
          end
        end
      end

      class ComponentLevel < self
        def set_parent_and_attribute_idhs!(parent_idh,opts={})
          ret = self
          @node_idhs = ret_matching_node_idhs(parent_idh)
          return ret if @node_idhs.empty?

          pattern  =~ /^node[^\/]*\/(component.+$)/
          cmp_fragment = $1
          @component_idhs = ret_matching_component_idhs(@node_idhs,cmp_fragment)
          return ret if @component_idhs.empty?
          
          cmp_fragment =~ /^component[^\/]*\/(attribute.+$)/  
          attr_fragment = $1
          @attribute_idhs = ret_matching_attribute_idhs(:component,@component_idhs,attr_fragment)
          ret
        end
      end

      #parent will be node_idh or assembly_idh
      def ret_matching_node_idhs(parent_idh)
        if parent_idh[:model_name] == :node
          return [parent_idh]
        end
        filter = [:eq, :assembly_id, parent_idh.get_id()]
        if node_filter = ret_filter(pattern,:node)
          filter = [:and, filter, node_filter]
        end
        sp_hash = {
          :cols => [:display_name,:id],
          :filter => filter
        }
        Model.get_objs(parent_idh.createMH(:node),sp_hash).map{|r|r.id_handle()}
      end

      def ret_matching_component_idhs(node_idhs,cmp_fragment)
        filter = [:oneof, :node_node_id, node_idhs.map{|idh|idh.get_id()}]
        if cmp_filter = ret_filter(cmp_fragment,:component)
          filter = [:and, filter, cmp_filter]
        end
        sp_hash = {
          :cols => [:display_name,:id],
          :filter => filter
        }
        sample_idh = node_idhs.first
        Model.get_objs(sample_idh.createMH(:component),sp_hash).map{|r|r.id_handle()}
      end

      def ret_matching_attribute_idhs(type,idhs,attr_fragment)
        filter = [:oneof, TypeToIdField[type], idhs.map{|idh|idh.get_id()}]
        if attr_filter = ret_filter(attr_fragment,:attribute)
          filter = [:and, filter, attr_filter]
        end
        sp_hash = {
          :cols => [:display_name,:id],
          :filter => filter
        }
        sample_idh = idhs.first
        Model.get_objs(sample_idh.createMH(:attribute),sp_hash).map{|r|r.id_handle()}
      end
      TypeToIdField = {
        :component => :component_component_id,
        :node => :node_node_id
      }
      def ret_filter(fragment,type)
        if term = Pattern::Term.extract_term?(fragment)
          if type == :component
            term = Component.display_name_from_user_friendly_name(term)
          end

          if term == "*"
            nil
          elsif term =~ /^[a-z0-9_\[\]-]+$/
            case type
            when :attribute, :component, :node
              [:eq,:display_name,term]
            else
              raise ErrorNotImplementedYet.new("Component filter of type (#{type})")
            end
          else
            raise ErrorNotImplementedYet.new("Parsing of component filter (#{term})")
          end
        else
          nil #without qualification means all (no filter)
        end
      end
    end

  end
end; end

