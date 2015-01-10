module DTK; class BaseModule; class UpdateModule
  class UpdateModuleRefs < self

    def initialize(dsl_obj,base_module)
      super(base_module)
      @input_hash    = dsl_obj.input_hash
      @project_idh   = dsl_obj.project_idh
      @module_branch = dsl_obj.module_branch
    end

    def self.update_component_module_refs(module_branch,dsl_info_to_add,base_module)
      ModuleRefs::Parse.update_component_module_refs(base_module.class,module_branch,:dsl_info_to_add => dsl_info_to_add)
    end

    def validate_includes_and_update_module_refs()
      ret = Hash.new
      unless includes = component_include_modules?()
        return ret
      end
      existing_dsl_info = get_component_module_refs_dsl_info()      
      return existing_dsl_info if is_parsing_error?(existing_dsl_info)
      # just keep existing_dsl_objs that have a namespace set
      existing_dsl_info.reject!{|r|!r.namespace?()}
      

      mapped = ModuleRefs::Component.get_matching(@project_idh,includes)

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
        # For Rich:
        # possible solution for problem that Bakir sent in his last email
        # uncomment these lines if caused any side effects
        # existing_module_refs = @module_branch.get_module_refs()
        # existing_module_refs.each do |existing_ref|
        #     existing_names << existing_ref[:display_name] if existing_ref[:namespace_info]
        # end
        
        # multiple_namespaces.delete_if{|mn| existing_names.include?(mn[:component_module])}
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
      
      ret.merge!(:external_dependencies => ExternalDependencies.new(ext_deps_hash))
      unless mapped.empty?
        self.class.update_component_module_refs(@module_branch,mapped,@base_module) 
        message = "The module refs file was updated by the server based on includes section from dtk.model.yaml"
        ret.merge!(:message => message)
      end
      ret
    end
    
   private
    # These are modules in teh component module include section of dtk.model.yaml
    def component_include_modules?()
      # @input_hash is in normalized form
      ret = @input_hash.values.map{|v|(v['component_include_module']||{}).keys}.flatten(1).uniq
      ret unless ret.empty?
    end
    
    # this is what is in dsl or parse error
    def get_component_module_refs_dsl_info()
      ModuleRefs::Component.get_dsl_info(@base_module.class,@module_branch)
    end

=begin
TODO get rid of get_existing_module_refs() which returns
{"component_modules"=>
  {"concat"=>{"namespace"=>"puppetlabs"},
   "staging"=>{"namespace"=>"r8"},
   "stdlib"=>nil}}
and instead use get_component_module_refs_dsl_info
=end
    
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
      if existing_content = RepoManager.get_file_content({:path => "module_refs.yaml"}, @module_branch, {:no_error_if_not_found => true})
        Aux.convert_to_hash(existing_content,:yaml) 
      else
        Hash.new
      end
    end
  end
end; end; end
    
