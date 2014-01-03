module DTK
  class ErrorUsage
    class DSLParsing
      module Mixin
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
          cmp = component_print_form(component_type, :node_name => node_name)
          "Bad link (#{link_def_ref}) for component (#{cmp})"
        end
      end

      class NotSupported < self
        include Mixin
        class LinkFromComponentWithTitle < self
          def initialize(node_name,component_type,title,opts={})
            super(base_msg(node_name,component_type,title),opts[:file_path])
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
  end
end
