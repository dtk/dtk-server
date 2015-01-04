module DTK; class ModuleDSL
  module ModuleRefsHelperClassMixin
    def update_component_module_refs(module_class,module_branch,opts={})
      syntatic_parsed_info = module_class::DSLParser.parse_directory(module_branch,:component_module_refs,opts)
      return syntatic_parsed_info if ParsingError.is_error?(syntatic_parsed_info)
      if opts[:match_hashes]
        syntatic_parsed_info << opts[:match_hashes]
        syntatic_parsed_info.flatten!
      end
      parsed_info = ModuleRefs::Parse.semantic_parse(module_branch,syntatic_parsed_info)
      return parsed_info if ParsingError.is_error?(parsed_info)
      ModuleRefs::Parse.update_from_dsl_parsed_info(module_branch,parsed_info)
    end
  end

  module ModuleRefsHelperMixin
    def validate_includes_and_update_module_refs_aux()
      ret = Hash.new

      # @input_hash is in normaized form
      includes = @input_hash.values.map{|v|(v['component_include_module']||{}).keys}.flatten(1)
      includes.uniq!
      unless includes.empty?
        multiple_namespaces = []
        all_modules = ComponentModule.get_all(@project_idh,[:namespace_id,:namespace])
        mapped = all_modules.select{|m| includes.include?(m[:display_name])}.map{|k| {:component_module=>k[:display_name],:remote_namespace=>k[:namespace][:name]}}
        multiple_namespaces = mapped.group_by { |h| h[:component_module] }.values.select { |a| a.size > 1 }.flatten

        mapped_names = mapped.map{|m| m[:component_module]}
        missing = includes - mapped_names
        ext_deps_hash = {
          :possibly_missing => missing
        }

        unless multiple_namespaces.empty?
          multi_missing, ambiguous_grouped, existing_names = [], {}, []
          multiple_namespaces.each{|mn| mapped.delete(mn)}

          check_if_matching_or_ambiguous(multiple_namespaces)
          existing_module_refs = @module_branch.get_module_refs()
          existing_module_refs.each do |existing_ref|
            existing_names << existing_ref[:display_name] if existing_ref[:namespace_info]
          end

          multiple_namespaces.delete_if{|mn| existing_names.include?(mn[:component_module])}
          cmp_mods = multiple_namespaces.group_by { |h| h[:component_module] }
          cmp_mods.each do |k,v|
            namespaces = v.map{|a| a[:remote_namespace]}
            ambiguous_grouped.merge!(k => namespaces)
          end
          unless ambiguous_grouped.empty?
            ret.merge!(:ambiguous => ambiguous_grouped)
            ext_deps_hash.merge!(:ambiguous => ambiguous_grouped)
          end
        end

        external_deps = ComponentModule::ExternalDependencies.new(ext_deps_hash)
        if poss_problems = external_deps.possible_problems?()
          ret.merge!(:external_dependencies => poss_problems)
        end

        ret.merge!(:match_hashes => mapped)
        unless mapped.empty?
          ModuleDSL.update_component_module_refs(ComponentModule,@module_branch,:match_hashes => mapped) 
        end
      end
      message = "The module refs file was updated by the server based on includes section from dtk.model.yaml"
      ret.merge(:message => message)
    end

   private
    def check_if_matching_or_ambiguous(ambiguous)
      existing_c_hash = get_existing_module_refs()
      if existing = existing_c_hash['component_modules']
        existing.each do |k,v|
          if k && v
            amb = ambiguous.select{|a| a[:component_module].split('/').last.eql?(k) && a[:remote_namespace].eql?(v['namespace'])}
            ambiguous.delete_if{|amb| amb[:component_module].split('/').last.eql?(k)} unless amb.empty?
          end
        end
      end
    end

    def get_existing_module_refs()
      existing_c_hash  = {}
      existing_content = RepoManager.get_file_content({:path => "module_refs.yaml"}, @module_branch, {:no_error_if_not_found => true})
      existing_c_hash  = Aux.convert_to_hash(existing_content,:yaml) if existing_content
      existing_c_hash
    end

  end
end; end
