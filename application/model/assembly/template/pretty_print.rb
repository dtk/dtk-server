module DTK
  class Assembly; class Template
    module PrettyPrint
      module Mixin
        def display_name_print_form(opts = {})
          if opts.empty?
            # TODO: may be able to get rid of this clause
            Template.pp_display_name(get_field?(:component_type))
          else
            Template.pretty_print_name(self, opts)
          end
        end
      end

      module ClassMixin
        PPModuleTemplateSep = '::'
        PPServiceModuleAssemblyDelim = '/'

        def pp_display_name(component_type)
          component_type.gsub(Regexp.new(Template::ModuleTemplateSep), PPModuleTemplateSep)
        end

        def pp_name_to_component_type(pp_name)
          pp_name.gsub(Regexp.new(PPModuleTemplateSep), Template::ModuleTemplateSep)
        end

        def pretty_print_name(assembly_template, opts = {})
          assembly_name, module_name = pretty_print_module_and_assembly(assembly_template, opts)
          if opts[:no_module_prefix] || module_name.nil?
            assembly_name
          elsif opts[:service_module_context_path]
            "#{module_name}/assembly/#{assembly_name}"
          else
            "#{module_name}#{PPServiceModuleAssemblyDelim}#{assembly_name}"
          end
        end

        #returns [assembly_template_name,module_name] in pretty print form
        def pretty_print_module_and_assembly(assembly_template, opts = {})
          assembly_name = module_name = nil
          if cmp_type = assembly_template.get_field?(:component_type)
            split = cmp_type.split(Template::ModuleTemplateSep)
            if split.size == 2
              module_name, assembly_name = split
            end
          end
          assembly_name ||= assembly_template.get_field?(:display_name) # heurstic

          if opts[:version_suffix]
            if version = pretty_print_version(assembly_template)
              assembly_name << "-v#{version}"
            end
          end
          if opts[:include_namespace]
            module_name = add_namespace_name(module_name, assembly_template)
          end
          [assembly_name, module_name]
        end

        def add_namespace_name(module_name, assembly_template)
          namespace_name = nil
          if namespace = assembly_template[:namespace]
            if namespace.is_a?(String)
              namespace_name = namespace
            elsif namespace.is_a?(Hash)
              namespace_name = namespace[:display_name]
            else
              raise Error.new('assembly_template[:namespace] is unexpected type')
            end
          end

          if namespace_name
            module_name && Namespace.join_namespace(namespace_name, module_name)
          else
            Log.error('Unexpected that opts[:include_namespace] is true and no namespace object in assembly')
            module_name
          end
        end
      end
    end
  end; end
end
