module DTK; class Attribute
  class Pattern 
    class Type

      r8_nested_require('type','explicit_id')      
      r8_nested_require('type','assembly_level')      

      def initialize(pattern)
        @pattern = pattern
      end

      def updated_attribute_idhs()
        (@created ? Array.new : attribute_idhs())
      end

      def created_attribute_idhs()
        (@created ? attribute_idhs() : Array.new)
      end

     private
      attr_reader :pattern, :id

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
        def component_instance()
          attribute_stack()[:component]
        end
        def node()
          attribute_stack()[:node]
        end
      end
       r8_nested_require('type','node_level')
       r8_nested_require('type','component_level')

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

