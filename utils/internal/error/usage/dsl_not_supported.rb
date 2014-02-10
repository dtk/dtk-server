module DTK
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
