module DTK
  class ServiceModule 
    class ParsingError < ModuleDSL::ParsingError
      r8_nested_require('parsing_error','dangling_component_refs')

      def initialize(msg,opts={})
        opts_file_path =  
          if opts.empty? 
            {:caller_info=>true}
          elsif opts[:file_path]
            if opts.size > 1
              raise Error.new("Not supported yet, need to cleanup so parent takes opts, rather than opts file path")
              #TODO: cleanup so parent takes opts, rather than opts file path
            else
              opts[:file_path]
            end
          else
            opts
          end
        super(msg,opts_file_path)
      end

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
