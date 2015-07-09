module DTK
  class DSLNotSupported < ErrorUsage::Parsing
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

    class LinkToNonComponent < self
      def initialize(opts={})
        raise ErrorUsage.new('Only supported: Attribute linked to a component attribute',Opts.new(opts).slice(:file_path))
      end
    end

    class LinkBetweenSameComponentTypes < self
      def initialize(cmp_instance,opts={})
        super(base_msg(cmp_instance),Opts.new(opts).slice(:file_path))
      end

      private

      def base_msg(cmp_instance)
        cmp_type_print_form = cmp_instance.component_type_print_form()
        raise ErrorUsage.new("Not supported: Attribute link involving same component type (#{cmp_type_print_form})")
      end
    end
  end
end
