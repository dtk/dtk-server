module DTK
  class ErrorUsage
    class DSLParsing
      class BadNodeReference < self
      end

      class BadComponentReference < self
      end

      class BadComponentLink < self
        def initialize(node_name,component_type,link_def_ref,opts={})
          super(base_msg(node_name,component_type,link_def_ref),opts[:file_path])
        end
       private 
        def base_msg(node_name,component_type,link_def_ref)
          "Bad link (#{link_def_ref}) for component #{node_name}/#{Component.component_type_print_form(component_type)}"
        end
      end
    end
  end
end
