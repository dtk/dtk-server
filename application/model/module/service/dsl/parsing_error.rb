module DTK
  class ServiceModule 
    class ParsingError < ModuleDSL::ParsingError
      r8_nested_require('parsing_error','dangling_component_refs')

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
          cmp = component_print_form(component_type, :node_name => node_name)
          "Bad link (#{link_def_ref}) for component (#{cmp})"
        end
      end
    end
  end
end
