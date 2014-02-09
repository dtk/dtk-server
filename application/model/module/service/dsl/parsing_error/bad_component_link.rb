module DTK
  class ServiceModule
    class ParsingError
      class BadComponentLink < self
        def initialize(link_def_ref,base_cmp_name,opts=Opts.new)
          err_params = Params.new(:link_def_ref => link_def_ref, :base_cmp_name => base_cmp_name)
          err_msg = "Component ?base_cmp_name's component link (?link_def_ref) refers to a component instance that does not exist"
          super(err_msg,err_params,opts)
        end
      end
    end
  end
end
