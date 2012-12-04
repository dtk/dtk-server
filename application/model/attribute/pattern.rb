#TODO: wil eventually persist so can save and reuse; wil put under probablty project
module DTK; class Attribute
  class Pattern 
    def self.set_attributes(base_object,av_pairs)
      ret = Array.new
      attribute_rows = Array.new
      #TODO: more efficient if can bulk up; and also return existing_attrs
      av_pairs.each do |av_pair|
        pattern = create(av_pair[:pattern])
        attr_idhs = pattern.ret_attribute_idhs(base_object.id_handle())
        unless attr_idhs.empty?
          attribute_rows += attr_idhs.map{|idh|{:id => idh.get_id(),:value_asserted => av_pair[:value]}}
        end
      end
      return ret if attribute_rows.empty?
      attr_ids = attribute_rows.map{|r|r[:id]}
      attr_mh = base_object.model_handle(:attribute)

      sp_hash = {
        :cols => [:id,:group_id,:display_name,:node_node_id,:component_component_id],
        :filter => [:oneof,:id,attribute_rows.map{|a|a[:id]}]
      }
      existing_attrs = Model.get_objs(attr_mh,sp_hash)
      ndx_new_vals = attribute_rows.inject(Hash.new){|h,r|h.merge(r[:id] => r[:value_asserted])}
      LegalValue.raise_usage_errors?(existing_attrs,ndx_new_vals)

      Attribute.update_and_propagate_attributes(attr_mh,attribute_rows)
      SpecialProcessing::Update.handle_special_processing_attributes(existing_attrs,ndx_new_vals)

      filter_proc = proc{|attr|attr_ids.include?(attr[:id])}
      base_object.info_about(:attributes,:filter_proc => filter_proc)
    end

    class Display
      def initialize(aug_attr,level=nil)
        @aug_attr = aug_attr #needs to be done first
        @level = level||find_level()
      end
      def print_form()
        display_name_prefix = 
          case @level
           when :assembly
            ""
           when :node
            "node[#{node[:display_name]}]/"
           when :component
            "node[#{node[:display_name]}]/cmp[#{component.display_name_print_form()}]/"
          end
        @aug_attr.print_form(display_name_prefix)
      end
     private
      def node()
        @aug_attr[:node]
      end
      def component()
        @aug_attr[:component]||@aug_attr[:nested_component]
      end
      def find_level()
        if node()
          component() ? :component : :node
        else
          :assembly
        end
      end
    end
  
    class Assembly < self
      def self.create(pattern)
        #can be an assembly, node or component level attribute
        if pattern =~ /^[0-9]+$/
          Type::ExplicitId.new(pattern)
        elsif pattern =~ /^attribute/
          Type::AssemblyLevel.new(pattern)
        elsif pattern  =~ /^node[^\/]*\/component/
          Type::ComponentLevel.new(pattern)
        elsif pattern  =~ /^node[^\/]*\/attribute/
          Type::NodeLevel.new(pattern)
        else
          raise ErrorParse.new(pattern)
        end
      end
    end
    
    class Node < self
      def self.create(pattern)
        if pattern =~ /^[0-9]+$/
          Type::ExplicitId.new(pattern)
        else
          raise ErrorParse.new(pattern)
        end
      end
    end

    class Type
      def ret_attribute_idhs(assembly_idh)
        raise Error.new("Should be overwritten")
      end

      class ExplicitId < self
        def ret_attribute_idhs(assembly_idh)
          [assembly_idh.createIDH(:model_name => :attribute, :id => id())]
        end
        private
        def id()
          @pattern
        end
      end

      class AssemblyLevel < self
        def ret_attribute_idhs(assembly_idh)
          ret = ret_matching_attribute_idhs([assembly_idh],pattern)
          #if does not exist then create the attribute
          if ret.empty?
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

      class ComponentLevel < self
        def ret_attribute_idhs(assembly_idh)
        ret = Array.new
          node_idhs = ret_matching_node_idhs(assembly_idh)
          return ret if node_idhs.empty?

          pattern  =~ /^node[^\/]*\/(component.+$)/
          cmp_fragment = $1
          cmp_idhs = ret_matching_component_idhs(node_idhs,cmp_fragment)
          return ret if cmp_idhs.empty?
          
          cmp_fragment =~ /^component[^\/]*\/(attribute.+$)/  
          attr_fragment = $1
          ret_matching_attribute_idhs(cmp_idhs,attr_fragment)
        end
      end

      private 
      def initialize(pattern)
        @pattern = pattern
      end
      attr_reader :pattern

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

      def ret_matching_attribute_idhs(cmp_idhs,attr_fragment)
        filter = [:oneof, :component_component_id, cmp_idhs.map{|idh|idh.get_id()}]
        if attr_filter = ret_filter(attr_fragment,:attribute)
          filter = [:and, filter, attr_filter]
        end
        sp_hash = {
          :cols => [:display_name,:id],
          :filter => filter
        }
        sample_idh = cmp_idhs.first
        Model.get_objs(sample_idh.createMH(:attribute),sp_hash).map{|r|r.id_handle()}
      end

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
            raise ErrorNotImplementedYet.new("Parsing of component fileter (#{filter})")
          end
        else
          nil #without qualification means all (no filter)
        end
      end
    end

    class ErrorParse < ErrorUsage
      def initialize(pattern)
        super("Cannot parse #{pattern}")
      end
    end
    class ErrorNotImplementedYet < Error
      def initialize(pattern)
        super("not implemented yet: #{pattern}")
      end
    end
  end
end; end

