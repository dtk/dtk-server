module DTK
  class ServiceModule
    class ParsingError
      class BadComponentLink < self
        def initialize(node_name,component_type,link_def_ref,opts=Opts.new)
          err_params = Params.new(:link_def_ref => link_def_ref, :cmp_ref => component_print_form(component_type, :node_name => node_name))
          err_msg = "Component (?cmp_ref) Component link (?link_def_ref) refers to a component that does not exist"
          super(err_msg,err_params,opts)
        end
      end
    end
  end
end
