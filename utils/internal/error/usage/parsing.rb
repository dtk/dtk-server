#TODO: cleanup; complication is that DSLParsing intesrsects with dtk common classes
module DTK
  class ErrorUsage 
    class Parsing < self
      class YAML < self
      end

      class Term < self
        def initialize(term,type_as_symbol=nil)
          msg =
            if type_as_symbol
              "Cannot parse #{type_print_form(type_as_symbol)} term: #{term}"
            else
              "Cannot parse term: #{term}"
            end
          super(msg)
        end
       private
        def type_print_form(type_as_symbol)
          type_as_symbol.to_s.gsub(/_/,' ')
        end
      end
    end

    class DSLParsing < self
      include DSLParsingAux

      def self.raise_error_unless(object,legal_values_input_form=[],&legal_values_block)
        legal_values = LegalValues.reify(legal_values_input_form,&legal_values_block)
        unless legal_values.match?(object)
          raise WrongType.new(object,legal_values,&legal_values_block)
        end
      end
      
      class WrongType < self
        def initialize(object,legal_values=[],&legal_values_block)
          super(LegalValues.reify(legal_values,&legal_values_block).error_message(object))
        end
      end

      def component_print_form(component_type,context={})
        ret = Component.component_type_print_form(component_type)
        if title = context[:title]
          ret = ComponentTitle.print_form_with_title(ret,title)
        end
          if node_name = context[:node_name]
            ret = "#{node_name}/#{ret}"
          end
        ret
      end
    end
  end

  class DSLNotSupported < ErrorUsage::DSLParsing
    class LinkBetweenSameComponentTypes < self
      def initialize(cmp_instance,opts={})
        super(base_msg(cmp_instance),opts[:file_path])
      end

     private
      def base_msg(cmp_instance)
        cmp_type_print_form = cmp_instance.component_type_print_form()
        raise ErrorUsage.new("Not supported: Attribute link involving same component type (#{cmp_type_print_form})")
      end
    end

    class LinkFromComponentWithTitle < self
      def initialize(node_name,component_type,title,opts={})
        super(base_msg(node_name,component_type,title),opts[:file_path])
      end

      def self.create_from_component(cmp_instance)
        node_name = cmp_instance.get_node()[:display_name]
        cmp_display_name = cmp_instance.get_field?(:display_name)
        component_type,title = ComponentTitle.parse_component_display_name(cmp_display_name)
        new(node_name,component_type,title)
      end

     private
      def base_msg(node_name,component_type,title)
        cmp = component_print_form(component_type, :node_name => node_name, :title => title)
        "Link from a component with a title, '#{cmp}' in this case, #{not_supported_msg()}"
      end
    end
       private
    def not_supported_msg()
      'is not supported'
    end
  end
end
