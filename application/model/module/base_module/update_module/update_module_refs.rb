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

      # find component modules in include_module_names that are missing
      missing = include_module_names - ndx_cmr_info.keys
      external_deps.merge!(:possibly_missing => missing) unless missing.empty?

      # find any ambiguously mapped component modules
      ambiguous = Hash.new
      include_module_names.each do |module_name|
        if matched_cmrs = ndx_cmr_info[module_name]
          if matched_cmrs.size > 1
            ambiguous[module_name] = matched_cmrs.map{|cmr|cmr.namespace}
          end
        end
      end
      external_deps.merge!(:ambiguous => ambiguous) unless ambiguous.empty?

      {:external_dependencies => external_deps}
    end

=begin
      unless mapped_cmrs.empty?
        update_component_module_refs(mapped_cmrs) 
        message = "The module refs file was updated by the server based on includes section from dtk.model.yaml"
        ret.merge!(:message => message)
      end

    end
=end    
   private
    # These are modules in the component module include section of dtk.model.yaml
    def component_module_names_in_include_statements?()
      # @input_hash is in normalized form
      ret = @input_hash.values.map{|v|(v['component_include_module']||{}).keys}.flatten(1).uniq
      ret unless ret.empty?
    end
  end
end; end; end
    
