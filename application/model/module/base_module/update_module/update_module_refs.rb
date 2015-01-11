module DTK; class BaseModule; class UpdateModule
  class UpdateModuleRefs < self

    def initialize(dsl_obj,base_module)
      super(base_module)
      @input_hash    = dsl_obj.input_hash
      @project_idh   = dsl_obj.project_idh
      @module_branch = dsl_obj.module_branch
    end

    # if an update is made it returns ModuleDSLInfo::UpdatedInfo object
    # opts can have keys
    # :message
    # :ret_dsl_updated_info
    def self.update_component_module_refs_dsl?(module_branch,external_deps,opts={})
      component_module_refs = opts[:component_module_refs] || ModuleRefs.get_component_module_refs(module_branch)
      #TODO: check for other things in external deps
      serialize_info_hash = (external_deps[:ambiguous] ? {:ambiguous => external_deps[:ambiguous]} : Hash.new)
      if new_commit_sha = component_module_refs.serialize_and_save_to_repo?(serialize_info_hash)
        if opts[:ret_dsl_updated_info]
          msg = opts[:message]||"The module refs file was updated by the server"
          ModuleDSLInfo::UpdatedInfo.new(:msg => msg,:commit_sha => new_commit_sha)
        end
      end
    end

    #this updates the component module objects, not the dsl
    def update_component_module_refs(dsl_info_to_add)
      self.class.update_component_module_refs(@module_branch,dsl_info_to_add,@base_module)
    end
    def self.update_component_module_refs(module_branch,dsl_info_to_add,base_module)
      ModuleRefs::Parse.update_component_module_refs(base_module.class,module_branch,:dsl_info_to_add => dsl_info_to_add)
    end
    #this updates the component module objects, not the dsl
    def validate_includes_and_update_module_refs()
      ret = Hash.new
      external_deps = ExternalDependencies.new()

      include_module_names = component_module_names_in_include_statements?()
      ndx_cmr_info = ModuleRefs::ComponentDSLForm.get_ndx_module_info(@project_idh,@base_module.class,@module_branch,:include_module_names => include_module_names)
      return ndx_cmr_info if is_parsing_error?(ndx_cmr_info)
      pp [:ndx_cmr_info,ndx_cmr_info]
      raise Error.new('got here')
    end

=begin
      # find namespaces in include_module_names that are missing

      missing = include_module_names - existing_dsl_info.map{|r|r.component_module()}
      external_deps.merge!(:possibly_missing => missing) unless missing.empty?

      #find existing component module refs that match the module_names in the modules in include statements
      mapped_cmrs = ModuleRefs::ComponentDSLForm.get_ones_that_match_module_names(@project_idh,include_module_names)


      multiple_namespaces = mapped_cmrs.group_by { |cmr| cmr.component_module}.values.select { |a| a.size > 1 }.flatten
      
      
      unless multiple_namespaces.empty?
        multi_missing, ambiguous_grouped, existing_names = [], {}, []
        multiple_namespaces.each{|mn| mapped_cmrs.delete(mn)}
        
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
      
      unless mapped_cmrs.empty?
        update_component_module_refs(mapped_cmrs) 
        message = "The module refs file was updated by the server based on includes section from dtk.model.yaml"
        ret.merge!(:message => message)
      end
      ret.merge(:external_dependencies => external_deps) 
    end
=end    
   private
    # These are modules in the component module include section of dtk.model.yaml
    def component_module_names_in_include_statements?()
      # @input_hash is in normalized form
      ret = @input_hash.values.map{|v|(v['component_include_module']||{}).keys}.flatten(1).uniq
      ret unless ret.empty?
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
    
