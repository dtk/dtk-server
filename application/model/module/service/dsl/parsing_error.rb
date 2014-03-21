module DTK
  class ServiceModule 
    class ParsingError < ErrorUsage::Parsing
      r8_nested_require('parsing_error','dangling_component_refs')
      r8_nested_require('parsing_error','bad_component_link')

      class BadNodeReference < self
        def initialize(params={})
          err_msg = "Bad node template (?node_template) in assembly '?assembly'"
          err_params = Params.new(:node_template => params[:node_template],:assembly => params[:assembly])
          super(err_msg,err_params)
        end
      end

      class BadComponentReference < self
      end
    end
  end
end
