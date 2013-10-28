module DTK; class Attribute
  class Pattern 
    class Type
      def initialize(pattern)
        @pattern = pattern
      end

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

        attr_reader :attribute_idhs

        def set_parent_and_attributes!(parent_idh,opts={})
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

      module CommonNodeComponentLevel
        def attribute_idhs()
          @attribute_stacks.map{|r|r[:attribute].id_handle()}
        end
        def attribute_name()
          attribute_stack()[:attribute][:display_name]
        end
        def attribute_id()
          attribute_stack()[:attribute].id()
        end
        def node()
          attribute_stack()[:node]
        end
      end

      class NodeLevel < self
        include CommonNodeComponentLevel

        def am_serialized_form()
          raise Error.new("Not implemented yet")
        end

        def component_instance()
          nil
        end

        def set_parent_and_attributes!(parent_idh,opts={})
          ret = self
          @attribute_stacks = Array.new
          ndx_nodes = ret_matching_nodes(parent_idh).inject(Hash.new){|h,r|h.merge(r[:id] => r)}
          return ret if ndx_nodes.empty?

          pattern =~ /^node[^\/]*\/(attribute.+$)/  
          attr_fragment = attr_name_special_processing($1)
          @attribute_stacks = ret_matching_attributes(:node,ndx_nodes.values.map{|r|r.id_handle()},attr_fragment).map do |attr|
            {
              :attribute => attr,
              :node => ndx_nodes[attr[:node_node_id]]
            }
          end
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
        include CommonNodeComponentLevel

        def am_serialized_form()
          "#{component_instance()[:component_type]}.#{attribute_name()}"
        end

        def component_instance()
          attribute_stack()[:component]
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

      def attribute_stack()
        unless @attribute_stacks.size == 1
          raise Error.new("attribute_stack() should only be called when @attribute_stacks.size == 1")
        end
        @attribute_stacks.first
      end
          
      #parent will be node_idh or assembly_idh
      def ret_matching_nodes(parent_idh)
        if parent_idh[:model_name] == :node
          return [parent_idh]
        end
        filter = [:eq, :assembly_id, parent_idh.get_id()]
        if node_filter = ret_filter(pattern,:node)
          filter = [:and, filter, node_filter]
        end
        sp_hash = {
          :cols => [:id,:group_id,:display_name],
          :filter => filter
        }
        Model.get_objs(parent_idh.createMH(:node),sp_hash)
      end

      def ret_matching_components(nodes,cmp_fragment)
        filter = [:oneof, :node_node_id, nodes.map{|r|r.id()}]
        if cmp_filter = ret_filter(cmp_fragment,:component)
          filter = [:and, filter, cmp_filter]
        end
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:component_type,:node_node_id,:ancestor_id],
          :filter => filter
        }
        cmp_mh = nodes.first.model_handle(:component)
        Model.get_objs(cmp_mh,sp_hash).map{|r|Component::Instance.create_from_component(r)}
      end

      def ret_matching_attributes(type,idhs,attr_fragment)
        filter = [:oneof, TypeToIdField[type], idhs.map{|idh|idh.get_id()}]
        if attr_filter = ret_filter(attr_fragment,:attribute)
          filter = [:and, filter, attr_filter]
        end
        sp_hash = {
          :cols => [:id,:group_id,:display_name,TypeToIdField[type]],
          :filter => filter
        }
        sample_idh = idhs.first
        Model.get_objs(sample_idh.createMH(:attribute),sp_hash)
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

