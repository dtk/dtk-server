module DTK
 class ModuleDSL
    class ParsingError < ErrorUsage::Parsing
      r8_nested_require('parsing_error','ref_component_templates')
      r8_nested_require('parsing_error','link_def')
      r8_nested_require('parsing_error','dependency')
      r8_nested_require('parsing_error','missing_key')
      r8_nested_require('parsing_error','illegal_keys')

      def initialize(msg='',*args_x)
        args = Params.add_opts(args_x,:error_prefix => ErrorPrefix,:caller_info => true)
        super(msg,*args)
      end
      ErrorPrefix = 'Component dsl parsing error'

      class MissingFromModuleRefs < self
        def initialize(params={})
          missing_modules = params[:modules]
          what = (missing_modules.size==1 ? "component module" : "component modules")
          is   = (missing_modules.size==1 ? "is" : "are")
          does = (missing_modules.size==1 ? "does" : "do")
          refs = missing_modules.join(',')

          err_msg = "The following #{what} (#{refs}) that #{is} referenced in includes section #{does} not exist in module refs file; this can be rectified by invoking the 'push' command after manually adding appropriate component module(s) to module refs file or by removing references in the DSL file(s)"
          # err_msg = "Component module(s) (?name) referenced in includes section are not specified in module refs file"
          err_params = Params.new(:modules => params[:modules].join(','))
          super(err_msg,err_params)
        end
      end

      class BadNamespaceReference < self
        def initialize(params={})
          err_msg = "Namespace (?name) referenced in module_refs file does not exist in local environment"
          err_params = Params.new(:name => params[:name])
          super(err_msg,err_params)
        end
      end

      class BadPuppetDefinition < self
        def initialize(params={})
          component = params[:component]
          invalid_names = params[:invalid_names]
          # missing_req_or_def = params[:missing_req_or_def]

          if invalid_names
            err_msg =
              (invalid_names.size == 0) ? "The following component (?name) that is mapped to puppet definition does not have designated name attribute"
                : "The following component (?name) that is mapped to puppet definition has multiple attributes designated as being the puppet definition name"
          # elsif missing_req_or_def
            # err_msg = "The following component (?name) that is mapped to puppet definition has name attribute that is not marked as required or does not have default value"
          end

          err_params = Params.new(:name => params[:component])
          super(err_msg,err_params)
        end
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


