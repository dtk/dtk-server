module DTK; class Attribute
  class Pattern
    class Type
      r8_nested_require('type','explicit_id')
      r8_nested_require('type','assembly_level')
      # common_node_component_level must be before node_level and component_level
      r8_nested_require('type','common_node_component_level')
      r8_nested_require('type','node_level')
      r8_nested_require('type','component_level')

      def initialize(pattern)
        @pattern = pattern
      end

      attr_writer :created
      def created?
        @created
      end

      def attribute_properties
        @attribute_properties||{}
      end

      def set_attribute_properties!(attr_properties)
        @attribute_properties = attr_properties
      end

      def valid_value?(value,attribute_idh=nil)
        attr = attribute_stack(attribute_idh)[:attribute]
        if semantic_data_type = attr[:semantic_data_type]
          # value comes as array inside string "[1, 2, 3]"; using JSON.parse to convert it to [1, 2, 3]
          value = JSON.parse(value) if semantic_data_type.eql?('array')
          SemanticDatatype.is_valid?(semantic_data_type,value)
        else
          # vacuously true
          true
        end
      end

      def semantic_data_type(attribute_idh=nil)
        attribute_stack(attribute_idh)[:attribute][:semantic_data_type]
      end

      # can be overwritten
      def node_group_member_attribute_idhs
        []
      end

      private

      attr_reader :pattern, :id

      def create_this_type?(opts)
        if create = opts[:create]
          create.is_a?(TrueClass) ||
            (create.is_a?(String) && create == 'true') ||
            (create.is_a?(Array) && create.include?(type()))
        end
      end

      def attribute_stack(attribute_idh=nil)
        if attribute_idh
          attr_id = attribute_idh.get_id()
          unless match = @attribute_stacks.find{|as|as[:attribute].id == attr_id}
            raise Error.new("Unexpceted that no match to attribute_id in attribute_stack")
          end
          match
        else
          unless @attribute_stacks.size == 1
            raise Error.new("attribute_stack() should only be called when @attribute_stacks.size == 1")
          end
          @attribute_stacks.first
        end
      end

      # parent will be node_idh or assembly_idh
      def ret_matching_nodes(parent_idh)
        if parent_idh[:model_name] == :node
          return [parent_idh]
        end
        filter = [:eq, :assembly_id, parent_idh.get_id()]
        if node_filter = ret_filter(pattern,:node)
          filter = [:and, filter, node_filter]
        end
        sp_hash = {
          cols: [:id,:group_id,:display_name],
          filter: filter
        }
        Model.get_objs(parent_idh.createMH(:node),sp_hash)
      end

      def ret_matching_components(nodes,cmp_fragment)
        filter = [:oneof, :node_node_id, nodes.map(&:id)]
        if cmp_filter = ret_filter(cmp_fragment,:component)
          filter = [:and, filter, cmp_filter]
        end
        sp_hash = {
          cols: [:id,:group_id,:display_name,:component_type,:node_node_id,:ancestor_id],
          filter: filter
        }
        cmp_mh = nodes.first.model_handle(:component)
        Model.get_objs(cmp_mh,sp_hash).map{|r|Component::Instance.create_from_component(r)}
      end

      def ret_matching_attributes(type,idhs,attr_fragment)
        filter = [:oneof, TypeToIdField[type], idhs.map(&:get_id)]
        if attr_filter = ret_filter(attr_fragment,:attribute)
          filter = [:and, filter, attr_filter]
        end
        sp_hash = {
          cols: [:id,:group_id,:display_name,:external_ref,:semantic_data_type,TypeToIdField[type]],
          filter: filter
        }
        sample_idh = idhs.first
        Model.get_objs(sample_idh.createMH(:attribute),sp_hash)
      end
      TypeToIdField = {
        component: :component_component_id,
        node: :node_node_id
      }

      def ret_filter(fragment,type)
        unless term = Pattern::Term.extract_term?(fragment)
          return nil #without qualification means all (no filter)
        end
        if term == "*"
          return nil
        end
        display_name = (type == :component ? ::DTK::Component::Instance.display_name_from_user_friendly_name(term) : term)
        if type == :node &&  ::DTK::Node.legal_display_name?(display_name)
          [:eq,:display_name,display_name]
        elsif type == :component && ::DTK::Component::Instance.legal_display_name?(display_name)
          [:eq,:display_name,display_name]
        elsif type == :attribute && Attribute.legal_display_name?(display_name)
          [:eq,:display_name,display_name]
        else
          # TODO: check why have :component_segment
          raise ErrorUsage::Parsing::Term.new(term,:component_segment)
        end
      end
    end
  end
end; end
