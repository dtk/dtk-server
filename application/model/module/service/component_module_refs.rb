module DTK
  class ServiceModule
    module ComponentModuleRefsMixin
      def set_component_module_version(component_module,component_version,service_version=nil)
        cmp_module_name = component_module.module_name()
        #make sure that component_module has version defined
        unless component_mb = component_module.get_module_branch_matching_version(component_version)
          defined_versions = component_module.get_module_branches().map{|r|r.version_print_form()}.compact
          version_info = 
            if defined_versions.empty?
              "there are no versions loaded"
            else
              "available versions: #{defined_versions.join(', ')}"
            end
          raise ErrorUsage.new("Component module (#{cmp_module_name}) does not have version (#{component_version}) defined; #{version_info}")
        end
        
        cmp_module_refs = get_component_module_refs(service_version)
        
        #check if set to this version already; if so no-op
        if cmp_module_refs.has_module_version?(cmp_module_name,component_version)
          return ret_clone_update_info(service_version)
        end
        
=begin
TODO: probably remove; ran into case where this is blocker; e.g., when want to change version before push-clone-changes
        #make sure that the service module references the component module
        unless cmp_module_refs.include_module?(cmp_module_name)

          #quick check is looking in component_module_refs, if no match then do more expensive
          #get_referenced_component_modules()
          unless service_module.get_referenced_component_modules().find{|r|r.module_name() == cmp_module_name}
            raise ErrorUsage.new("Service module (#{module_name()}) does not reference component module (#{cmp_module_name})")
          end        
        end
=end

        #set in cmp_module_refs the module have specfied value and update both model and service's global refs
        cmp_module_refs.set_module_version(cmp_module_name,component_version)
        
        #update the component refs with the new component_template_ids
        update_component_template_ids(component_module)
        
        ret_clone_update_info(service_version)
      end

     private
      def get_component_module_refs(service_version=nil)
        branch = get_module_branch_matching_version(service_version)
        ComponentModuleRefs.get_component_module_refs(branch)
      end

      def update_component_template_ids(component_module)
        #first get filter so can call get_augmented_component_refs
        assembly_templates = component_module.get_associated_assembly_templates()
        return if assembly_templates.empty?
        filter = [:oneof, :id, assembly_templates.map{|r|r[:id]}]
        opts = {:filter => filter,:force_compute_template_id => true}
        aug_cmp_refs = Assembly::Template.get_augmented_component_refs(model_handle(:component),opts)
        return if aug_cmp_refs.empty?
        cmp_ref_update_rows = aug_cmp_refs.map{|r|r.hash_subset(:id,:component_template_id)}
        Model.update_from_rows(model_handle(:component_ref),cmp_ref_update_rows)
      end
    end
  end

  class ComponentModuleRefs 
    def self.get_component_module_refs(branch)
      content_hash_content = ComponentModuleRef.get_component_module_refs(branch).inject(Hash.new) do |h,r|
        h.merge(key(r[:component_module]) => r)
      end
      new(branch,content_hash_content)
    end

    def self.update_from_dsl_hash(module_branch,dsl_hash,opts={})
      if dsl_hash.empty?
      elsif dsl_hash.size == 1 and dsl_hash.keys.first.to_sym == :component_modules
        update(module_branch,reify_content(dsl_hash.values.first),opts)
      else
        raise Error.new("Do not treat module verions contraints of form (#{dsl_hash.inspect})")
      end
      self
    end

    def ret_versions_indexed_by_modules()
      component_modules.inject(Hash.new) do |h,(mod,mod_info)|
        h.merge(mod.to_s => mod_info.version())
      end
    end

    def self.meta_filename_path()
      "global_module_refs.json"
    end

    #TODO: we may simplify relationship of component ref to compoennt template to simplify and make more efficient below
    #augmented with :component_template key which points to associated component template or nil 
    def set_matching_component_template_info!(aug_cmp_refs,opts={})
      ret = aug_cmp_refs
      return ret if aug_cmp_refs.empty?
      #for each element in aug_cmp_ref, want to set cmp_template_id using following rules
      # 1) if key 'has_override_version' is set
      #    a) if it points to a component template, use this
      #    b) otherwise look it up using given version
      # 2) else look it up and if lookup exists use this as the value to use; element marked required if it does not point to a component template
      cmp_types_to_check = Hash.new
      aug_cmp_refs.each do |r|
        unless cmp_type = r[:component_type]||(r[:component_template]||{})[:component_type]
          ref =  ComponentRef.print_form(r)
          ref = (ref ? "(#{ref})" : "")
          raise Error.new("Component ref #{ref} must either point to a component template or have component_type set")
        end
        if r[:has_override_version]
          unless r[:component_template_id]
            unless r[:version]
              raise Error.new("Component ref has override-version flag set, but no version")
            end
            (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r, :version => r[:version]}
          end
        else
          if r[:template_id_synched] and not opts[:force_compute_template_id]
            raise Error.new("Unexpected that r[:component_template_id] is null for (#{r.inspect})") if r[:component_template_id].nil?
          else
            (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r,:required => r[:component_template_id].nil?}
          end
        end
        r[:template_id_synched] = true #marking each item synchronized
      end

      #shortcut if no locked versions and no required elements
      if component_modules().empty? and not cmp_types_to_check.values.find{|r|r.mapping_required?()}
        return ret
      end

      #Lookup up modules mapping
      #mappings will have key for each component type referenced and for each key will return hash with keys :component_template and :version;
      #component_template will be null if no match is found
      mappings = get_component_type_to_template_mappings?(cmp_types_to_check.keys)

      #set the component template ids; raise error if there is a required element that does not have a matching component template
      reference_errors = Array.new
      cmp_types_to_check.each do |cmp_type,els|
        els.each do |el|
          cmp_type_version_info = mappings[cmp_type]
          if cmp_template = cmp_type_version_info[:component_template]
            el[:pntr][:component_template_id] = cmp_template[:id] 
            unless opts[:donot_set_component_template]
              el[:pntr][:component_template] = cmp_template
            end
          elsif el[:required]
            cmp_ref = {
              :component_type => cmp_type, 
              :version => cmp_type_version_info[:version]
            }
            remote_namespace = nil #TODO: stub to find remote namespace associated with module
            cmp_ref.merge!(:remote_namespace => remote_namespace) if remote_namespace
            reference_errors << cmp_ref
          end
        end
      end
      raise ErrorUsage::DanglingComponentRefs.new(reference_errors) unless reference_errors.empty?
      ret
    end
                                                                          
    def has_module_version?(cmp_module_name,version)
      module_version(cmp_module_name).version == version
    end

    def include_module?(cmp_module_name)
      component_modules.has_key?(key(cmp_module_name))
    end

    def set_module_version(cmp_module_name,version)
      cmp_module_key = key(cmp_module_name)
      #TODO: update to do merge when self has more than version info
      pntr = @component_modules[cmp_module_key] = ComponentModuleRef::VersionInfo::Assignment.new(version)
      self.class.update(@parent,{cmp_module_key => pntr})
      #TODO: here may search through 'linked' component instances and change version associated with them
    end

    def content_in_hash_form()
      self.class.hash_form(@component_modules)
    end

   private
    attr_reader :component_modules
    def initialize(parent,content_hash_form)
      @parent = parent
      @component_modules = self.class.reify_content(content_hash_form)
    end

    def self.reify_content(hash)
      if hash.empty? then hash
      else
        reify_component_module_version_info(hash)
      end
    end

    def self.reify_component_module_version_info(hash)
      ret = Hash.new
      hash.each_pair do |k,v|
        if version_info = ComponentModuleRef::VersionInfo::Assignment.reify?(v)
          ret.merge!(key(k) => version_info)
        end
      end
      ret
    end

    def self.key(el)
      el.to_sym
    end
    def key(el)
      self.class.key(el)
    end

    def self.update(parent,cmp_modules,opts={})
      ComponentModuleRef.create_or_update(parent,cmp_modules)

      unless opts[:donot_make_repo_changes]
        meta_filename_path = meta_filename_path()
        parent.serialize_and_save_to_repo(meta_filename_path,get_hash_content(parent))
      end
    end

    def self.get_hash_content(service_module_branch)
      ret = SimpleOrderedHash.new()
      component_module_refs = get_component_module_refs(service_module_branch)
      unordered_hash = component_module_refs.content_in_hash_form()
      if unordered_hash.empty?
        return ret
      end
      unless unordered_hash.size == 1 and unordered_hash.keys.first == :component_modules
        raise Error.new("Unexpected key(s) in component_module_refs (#{unordered_hash.keys.join(',')})")
      end
      
      cmp_mods = unordered_hash[:component_modules]
        cmp_mod_contraints = cmp_mods.keys.map{|x|x.to_s}.sort().inject(SimpleOrderedHash.new()){|h,k|h.merge(k => cmp_mods[k.to_sym])}
      ret.merge(:component_modules => cmp_mod_contraints)
    end

    class ComponentTypeToCheck < Array
      def mapping_required?()
        find{|r|r[:required]}
      end
    end

    def get_needed_component_type_version_pairs(cmp_types)
      cmp_types.map do |cmp_type|
        version = ret_selected_version(cmp_type)
        {:component_type => cmp_type, :version => version, :version_field => ModuleBranch.version_field(version)}
      end
    end

    def get_component_type_to_template_mappings?(cmp_types)
      ret = Hash.new
      return ret if cmp_types.empty?
      #first put in ret info about component type and version
      ret = cmp_types.inject(Hash.new) do |h,cmp_type|
        version = ret_selected_version(cmp_type)
        h.merge(cmp_type => {:component_type => cmp_type, :version => version, :version_field => ModuleBranch.version_field(version)})
      end

      #get matching component template info and insert matches into ret
      Component::Template.get_matching_type_and_version(project_idh(),ret.values).each do |cmp_template|
        ret[cmp_template[:component_type]].merge!(:component_template => cmp_template) 
      end
      ret
    end

    def ret_selected_version(component_type)
      if version_info = component_modules[key(Component.module_name(component_type))]
        version_info.version()
      end
    end

    def module_version(cmp_module_name)
      ComponentModuleRef::VersionInfo::Assignment.new(component_modules[key(cmp_module_name)])
    end
    
    def self.hash_form(el)
      if el.kind_of?(Hash)
        el.inject(Hash.new) do |h,(k,v)|
          if val = hash_form(v)
             h.merge(k => val)
          else
            h
          end
        end
      elsif el.kind_of?(ComponentModuleRef::VersionInfo)
        el.to_s
      else
        el
      end
    end

    def project_idh()
      return @project_idh if @project_idh
      unless service_id = @parent.get_field?(:service_id)
        raise Error.new("Cannot find project from parent object")
      end
      service_module = @parent.model_handle(:service_module).createIDH(:id => service_id).create_object()
      unless project_id = service_module.get_field?(:project_project_id)
        raise Error.new("Cannot find project from parent object")
      end
      @parent.model_handle(:project).createIDH(:id => project_id)
    end
    
  end
end
