module DTK
  class ServiceModule 
    class ParsingError < ModuleDSL::ParsingError
      r8_nested_require('parsing_error','dangling_component_refs')
      r8_nested_require('parsing_error','bad_component_link')

      class BadNodeReference < self
      end
      
      class BadComponentReference < self
      end
    end
  end
end
