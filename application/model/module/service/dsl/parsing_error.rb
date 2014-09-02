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

      class AmbiguousModuleRef < self
        def initialize(params={})
          err_msg = "Reference to ?module_type module (?module_name) is ambiguous; it belongs to the namespaces (?namespaces); one of these namespaces should be selected by editing the module_refs file"
          
          err_params = Params.new(
            :module_type => params[:module_type],
            :module_name => params[:module_name],
            :namespaces => params[:namespaces].join(',')
          )
          super(err_msg,err_params)
        end
      end
    end
  end
end
