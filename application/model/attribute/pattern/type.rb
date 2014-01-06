module DTK; class Attribute
  class Pattern 
    class Type

      r8_nested_require('type','explicit_id')      
      r8_nested_require('type','assembly_level')      

      def initialize(pattern)
        @pattern = pattern
      end

      attr_writer :created
      def created?()
        @created
      end
      def attribute_properties()
        @attribute_properties||{}
      end
      def set_attribute_properties!(attr_properties)
        @attribute_properties = attr_properties
      end

      def valid_value?(value,attribute_idh=nil)
        attr = attribute_stack(attribute_idh)[:attribute]
        if semantic_data_type = attr[:semantic_data_type]
          SemanticDatatype.is_valid?(semantic_data_type,value)
        else
          #vacuously true
          true
        end
      end

      def semantic_data_type(attribute_idh=nil)
        attribute_stack(attribute_idh)[:attribute][:semantic_data_type]
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
        def component_instances()
          @attribute_stacks.map{|as|as[:component]}.compact
        end
        def node()
          attribute_stack()[:node]
        end
       private
        def create_attributes(attr_parents)
          attribute_idhs = Array.new
          attr_properties = attribute_properties().inject(Hash.new){|h,(k,v)|h.merge(k.to_s => v)}
          field_def = 
            {'display_name' => pattern_attribute_name()}.merge(attr_properties)
          attr_parents.each do |attr_parent|
            attribute_idhs += Attribute.create_or_modify_field_def(attr_parent,field_def)
          end
          
          return attribute_idhs if attribute_idhs.empty?
          
          #TODO: can make more efficient by having create_or_modify_field_def return object with cols, rather than id_handles
          sp_hash = {
            :cols => [:id,:group_id,:display_name,:description,:component_component_id,:data_type,:semantic_type,:required,:dynamic,:external_ref,:semantic_data_type],
            :filter => [:oneof,:id,attribute_idhs.map{|idh|idh.get_id()}]
          }
          attr_mh = attribute_idhs.first.createMH()
          Model.get_objs(attr_mh,sp_hash)
        end

        def pattern_attribute_name()
          first_name_in_fragment(pattern_attribute_fragment())
        end
        
        def first_name_in_fragment(fragment)
          fragment =~ NameInFragmentRegexp
          $1
        end
        NameInFragmentRegexp = /[^<]*<([^>]*)>/
      end
      r8_nested_require('type','node_level')
      r8_nested_require('type','component_level')

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
          :cols => [:id,:group_id,:display_name,:external_ref,:semantic_data_type,TypeToIdField[type]],
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
          non_processed_term = term
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
              raise ErrorUsage::NotSupported.new("Component filter of type (#{type})")
            end
          else
            raise ErrorUsage::Parsing::Term.new(non_processed_term,:component_segment)
          end
        else
          nil #without qualification means all (no filter)
        end
      end

    end
  end
end; end

