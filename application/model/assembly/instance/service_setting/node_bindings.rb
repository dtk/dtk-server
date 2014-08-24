module DTK
  class ServiceSetting
    class NodeBindings < Array
      def set_node_bindings(assembly)
        hash_content = inject(Hash.new){|h,el|h.merge(el.hash_form)}
        ServiceModule::AssemblyImport.process_node_binding_settings(hash_content)
      end
      def self.each_element(content,&block)
        content.each_pair do |assembly_node,node_target|
          block.call(Element.new(assembly_node,node_target))
        end
      end
      class Element
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
