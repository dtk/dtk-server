module DTK
  class ErrorUsage
    class DSLParsing
      module Mixin
        def component_print_form(component_type,node_name=nil)
          cmp = Component.component_type_print_form(component_type)
          node_name ? "#{node_name}/#{cmp}" : cmp
        end
      end

      class BadNodeReference < self
      end

      class BadComponentReference < self
      end

      class BadComponentLink < self
        include Mixin
        def initialize(node_name,component_type,link_def_ref,opts={})
          super(base_msg(node_name,component_type,link_def_ref),opts[:file_path])
        end
       private 
        def base_msg(node_name,component_type,link_def_ref)
          "Bad link (#{link_def_ref}) for component #{component_print_form(component_type,node_name)}"
        end
      end

      class NotSupported < self
        include Mixin
        class LinkFromComponentWithTitle < self
          def initialize(node_name,component_type)
            super(base_msg(node_name,component_type))
          end
         private
          def base_msg(component_type)
            "Link from component with title (#{component_print_form(component_type)} #{not_supported_msg()}"
          end
        end
       private
        def not_supported_msg()
          'is not supported'
        end
      end
    end
  end
end
