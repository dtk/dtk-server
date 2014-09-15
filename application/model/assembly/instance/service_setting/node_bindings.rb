module DTK
  class ServiceSetting
    class NodeBindings < Array
      def initialize(content)
        super()
        self.class.each_element(content){|el|self << el}
      end

      def set_node_bindings(target,assembly)
        hash_content = inject(Hash.new){|h,el|h.merge(el.hash_form)}
        ::DTK::NodeBindings::DSL.set_node_bindings(target,assembly,hash_content)
      end

     private
      def self.each_element(content,&block)
        content.each_pair do |assembly_node,node_target|
          block.call(Element.new(assembly_node,node_target))
        end
      end

      class Element
        attr_reader :assembly_node
        def initialize(assembly_node,node_target)
          @assembly_node = assembly_node
          @node_target = node_target
        end
        def hash_form()
          {@assembly_node => @node_target}
        end
      end
    end
  end
end
