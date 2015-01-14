module DTK; class BaseModule; class UpdateModule
  class UpdateModuleRefs < self

    def initialize(dsl_obj,base_module)
      super(base_module)
      @input_hash    = dsl_obj.input_hash
      @project_idh   = dsl_obj.project_idh
      @module_branch = dsl_obj.module_branch
    end

    # opts can have keys
    #  :message
    #  :create_empty_module_refs
    #  :external_dependencies
    def self.update_component_module_refs_and_save_dsl?(module_branch,cmr_update_els,base_module,opts={})
      component_module_refs = update_component_module_refs(module_branch,cmr_update_els,base_module)
      save_dsl?(module_branch,opts.merge(:component_module_refs => component_module_refs))
    end

    def self.update_component_module_refs(module_branch,cmr_update_els,base_module)
      ModuleRefs::Parse.update_component_module_refs_from_parse_objects(base_module.class,module_branch,cmr_update_els)
    end
    def update_component_module_refs(cmr_update_els)
      self.class.update_component_module_refs(@module_branch,cmr_update_els,@base_module)
    end
    private :update_component_module_refs


    # if an update is made it returns ModuleDSLInfo::UpdatedInfo object
    # opts can have keys
    #  :message
    #  :create_empty_module_refs
    #  :component_module_refs 
    #  :external_dependencies 
    def self.save_dsl?(module_branch,opts={})
      component_module_refs = opts[:component_module_refs] || ModuleRefs.get_component_module_refs(module_branch)
      serialize_info_hash = Aux::hash_subset(opts,[:create_empty_module_refs])
      if external_deps = opts[:external_dependencies]
        if ambiguous = external_deps.ambiguous?
          serialize_info_hash.merge!(:ambiguous => ambiguous)
        end
        if possibly_missing = external_deps.possibly_missing?
          serialize_info_hash.merge!(:possibly_missing => possibly_missing)
        end
      end
      serialize_info_hash.merge!(:create_empty_module_refs => true)
      # TODO: for efficiency if have the parsed info can pass this to serialize_and_save_to_repo?
      if new_commit_sha = component_module_refs.serialize_and_save_to_repo?(serialize_info_hash)
        msg = opts[:message]||"The module refs file was updated by the server"
        ModuleDSLInfo::UpdatedInfo.new(:msg => msg,:commit_sha => new_commit_sha)
      end
    end

    #this updates the component module objects, not the dsl
    def validate_includes_and_update_module_refs()
      ret = Hash.new
      external_deps = ExternalDependencies.new()

      include_module_names = component_module_names_in_include_statements?()
      # ModuleRefs::ComponentDSLForm will also find any parsing errors in the module refs file
      ndx_cmr_info = ModuleRefs::ComponentDSLForm.get_ndx_module_info(@project_idh,@module_class,@module_branch,:include_module_names => include_module_names)
      return ndx_cmr_info if is_parsing_error?(ndx_cmr_info)

      # process includes (if they exist)
      unless include_module_names.nil? or include_module_names.empty?
        # find component modules in include_module_names that are missing
        missing = include_module_names - ndx_cmr_info.keys
        external_deps.merge!(:possibly_missing => missing) unless missing.empty?
        
        # find any ambiguously mapped component modules
        ambiguous = Hash.new
        include_module_names.each do |module_name|
          if match_info = ndx_cmr_info[module_name]
            if match_info.match_type == :multiple_match
              ambiguous[module_name] = match_info.match_array.map{|cmr|cmr.namespace}
            end
          end
        end
        external_deps.merge!(:ambiguous => ambiguous) unless ambiguous.empty?
      end

      # update the component_module_ref objects from elements of ndx_cmr_info that are unique
      cmr_update_els = ModuleRefs::ComponentDSLForm::Elements.new
      ndx_cmr_info.each_value do |match_info|
        if [:dsl,:unique_match].include?(match_info.match_type)
          cmr_update_els.add!(match_info.match_array)
        end
      end
      ModuleRefs::Parse.update_component_module_refs_from_parse_objects(@module_class,@module_branch,cmr_update_els)

      {:external_dependencies => external_deps}
    end

=begin
      TODO: For Aldin: this is fragment that was in old code above does not have message in ret; might
      want to put in back in
      unless mapped_cmrs.empty?
        update_component_module_refs(mapped_cmrs) 
        message = "The module refs file was updated by the server based on includes section from dtk.model.yaml"
        ret.merge!(:message => message)
      end

    end
=end    

    # These are modules in the component module include section of dtk.model.yaml
    def component_module_names_in_include_statements?()
      # @input_hash is in normalized form
      ret = @input_hash.values.map{|v|(v['component_include_module']||{}).keys}.flatten(1).uniq
      ret unless ret.empty?
    end
  end
end; end; end
    
