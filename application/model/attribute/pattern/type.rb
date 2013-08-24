#TODO: this are written to focus on assemblies; need to modify to treat nodes too
module DTK; class Attribute
  class Pattern 
    class Type
      def initialize(pattern)
        @pattern = pattern
      end
     private
      attr_reader :pattern, :id

      class ExplicitId < self
        def initialize(pattern,base_obj)
          super(pattern)
          @id = pattern.to_i
          if base_obj.kind_of?(::DTK::Node)
            raise_error_if_not_node_attr_id(@id,base_obj)
          elsif base_obj.kind_of?(::DTK::Assembly)
            raise_error_if_not_assembly_attr_id(@id,base_obj)
          else
            raise Error.new("Unexpected base object type (#{base_obj.class.to_s})")
          end
        end

        def ret_or_create_attributes(assembly_idh,opts={})
          [assembly_idh.createIDH(:model_name => :attribute, :id => id())]
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

      class AssemblyLevel < self
        def ret_or_create_attributes(assembly_idh,opts={})
          ret = ret_matching_attribute_idhs(:component,[assembly_idh],pattern)
          #if does not exist then create the attribute if carete flag set
          #if exists and create flag exsists we just assign it new value
          if ret.empty? and opts[:create]
            af = ret_filter(pattern,:attribute)
            #attribute must have simple form 
            unless af.kind_of?(Array) and af.size == 3 and af[0..1] == [:eq,:display_name]
              raise Error.new("cannot create new attribute from attribute pattern #{pattern}")
            end
            field_def = {"display_name" => af[2]}
            ret = assembly_idh.create_object().create_or_modify_field_def(field_def)
          end
          ret
        end
      end

      class NodeLevel < self
        def ret_or_create_attributes(assembly_idh,opts={})
          ret = Array.new
          node_idhs = ret_matching_node_idhs(assembly_idh)
          return ret if node_idhs.empty?

          pattern =~ /^node[^\/]*\/(attribute.+$)/  
          attr_fragment = attr_name_special_processing($1)
          ret_matching_attribute_idhs(:node,node_idhs,attr_fragment)
        end
       private
        def attr_name_special_processing(attr_fragment)
          #TODO: make this obtained from shared logic
          if attr_fragment == 'attribute[host_address]'
            'attribute[host_addresses_ipv4]'
          else
            attr_fragment
          end
        end
      end

      class ComponentLevel < self
        def ret_or_create_attributes(assembly_idh,opts={})
          ret = Array.new
          node_idhs = ret_matching_node_idhs(assembly_idh)
          return ret if node_idhs.empty?

          pattern  =~ /^node[^\/]*\/(component.+$)/
          cmp_fragment = $1
          cmp_idhs = ret_matching_component_idhs(node_idhs,cmp_fragment)
          return ret if cmp_idhs.empty?
          
          cmp_fragment =~ /^component[^\/]*\/(attribute.+$)/  
          attr_fragment = $1
          ret_matching_attribute_idhs(:component,cmp_idhs,attr_fragment)
        end
      end

      #TODO: more efficient to use joins of below
      def ret_matching_node_idhs(assembly_idh)
        filter = [:eq, :assembly_id, assembly_idh.get_id()]
        if node_filter = ret_filter(pattern,:node)
          filter = [:and, filter, node_filter]
        end
        sp_hash = {
          :cols => [:display_name,:id],
          :filter => filter
        }
        Model.get_objs(assembly_idh.createMH(:node),sp_hash).map{|r|r.id_handle()}
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
        if fragment =~ /[a-z]\[([^\]]+)\]/
          filter = $1
          if type == :component
            filter = Component.component_type_from_user_friendly_name(filter)
          end
          if filter == "*"
            nil
          elsif filter =~ /^[a-z0-9_-]+$/
            case type
            when :attribute
              [:eq,:display_name,filter]
            when :component
              [:eq,:component_type,filter]
            when :node
              [:eq,:display_name,filter]
            else
              raise ErrorNotImplementedYet.new("Component filter of type (#{type})")
            end
          else
            raise ErrorNotImplementedYet.new("Parsing of component filter (#{filter})")
          end
        else
          nil #without qualification means all (no filter)
        end
      end
    end

  end
end; end

