module DTK
  class ModuleRefs 
    r8_nested_require('module_refs','mixin')
    r8_nested_require('module_refs','parse')
    def self.get_component_module_refs(branch)
      content_hash_content = ModuleRef.get_component_module_refs(branch).inject(Hash.new) do |h,r|
        h.merge(key(r[:module_name]) => r)
      end
      new(branch,content_hash_content)
    end
    
    def version_objs_indexed_by_modules()
      ret = Hash.new
      component_modules.each_pair do |mod,cmr|
        if version_info =  cmr[:version_info]
          ret.merge!(mod.to_s => version_info)
        end
      end
      ret
    end
    
    def update_component_template_ids(component_module)
      # first get filter so can call get_augmented_component_refs
      assembly_templates = component_module.get_associated_assembly_templates()
      return if assembly_templates.empty?
      filter = [:oneof, :id, assembly_templates.map{|r|r[:id]}]
      opts = {
        :filter => filter,
        :component_module_refs => self,
        :force_compute_template_id => true,
        :raise_errors_if_unmatched => true
      }
      aug_cmp_refs = Assembly::Template.get_augmented_component_refs(component_module.model_handle(:component),opts)
      return if aug_cmp_refs.empty?
      cmp_ref_update_rows = aug_cmp_refs.map{|r|r.hash_subset(:id,:component_template_id)}
      Model.update_from_rows(component_module.model_handle(:component_ref),cmp_ref_update_rows)
    end

    # augmented with :component_template key which points to associated component template or nil 
    def set_matching_component_template_info!(aug_cmp_refs,opts={})
      ret = aug_cmp_refs
      return ret if aug_cmp_refs.empty?
      # for each element in aug_cmp_ref, want to set cmp_template_id using following rules
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
        cmp_template_id = r[:component_template_id]
        if r[:has_override_version]
          unless cmp_template_id
            unless r[:version]
              raise Error.new("Component ref has override-version flag set, but no version")
            end
            (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r, :version => r[:version]}
          end
        else
          add_item = true
          if r[:template_id_synched] and not opts[:force_compute_template_id]
            if cmp_template_id.nil?
              Log.error("Unexpected that cmp_template_id is null for (#{r.inspect})")
            else
              add_item = false
            end
          end
          if add_item
            (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r,:required => cmp_template_id.nil?}
          end
        end
        r[:template_id_synched] = true #marking each item synchronized
      end

      # shortcut if no locked versions and no required elements
      if component_modules().empty? and not cmp_types_to_check.values.find{|r|r.mapping_required?()}
        return ret
      end

      # Lookup up modules mapping
      # mappings will have key for each component type referenced and for each key will return hash with keys :component_template and :version;
      # component_template will be null if no match is found
      mappings = get_component_type_to_template_mappings?(cmp_types_to_check.keys,opts)

      # set the component template ids; raise error if there is a required element that does not have a matching component template
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
      raise ServiceModule::ParsingError::DanglingComponentRefs.new(reference_errors) unless reference_errors.empty?
      ret
    end

    attr_reader :component_modules
                                                                          
    def has_module_version?(cmp_module_name,version_string)
      if cmp_module_ref = ret_component_module_ref(cmp_module_name)
        cmp_module_ref.version_string() == version_string
      end
    end

    def include_module?(cmp_module_name)
      component_modules.has_key?(key(cmp_module_name))
    end

    def ret_service_module_info()
      sp_hash = {
        :cols => [:service_module_info]
      }
      service_module = get_obj(sp_hash)
      service_module
    end

    def set_module_version(cmp_module_name,version)
      key = key(cmp_module_name)
      if cmr = @component_modules[key]
        cmr.set_module_version(version)
      else
        hash_content = {
          :component_module => cmp_module_name,
          :version_info => version
        }
        @component_modules[key] = ModuleRef.reify(@parent.model_handle,hash_content)
      end
      self.class.update(@parent,@component_modules)
    end

   private
    def ret_component_module_ref(cmp_module_name)
      @component_modules[key(cmp_module_name)]
    end

    def initialize(parent,content_hash_form,opts={})
      @parent = parent
      @component_modules = opts[:content_hash_form_is_reified] ?
        content_hash_form :
        Parse.reify_content(parent.model_handle(:model_ref),content_hash_form)
    end

    def self.key(el)
      el.to_sym
    end
    def key(el)
      self.class.key(el)
    end

    MetaFilenamePath = 'global_module_refs.json'
    def self.meta_filename_path()
      MetaFilenamePath
    end

    def self.update(parent,cmp_modules,opts={})
      ModuleRef.create_or_update(parent,cmp_modules)

      unless opts[:donot_make_repo_changes]
        meta_filename_path = meta_filename_path()
        parent.serialize_and_save_to_repo(meta_filename_path,dsl_hash_form(parent))
      end
    end

    def self.dsl_hash_form(service_module_branch)
      ret = SimpleOrderedHash.new()
      component_modules = get_component_module_refs(service_module_branch).component_modules

      dsl_hash_form = Hash.new
      component_modules.each_pair do |cmp_module_name,cmr|
        hf = cmr.dsl_hash_form()
        dsl_hash_form[cmp_module_name.to_s] = hf unless hf.empty?
      end

      if dsl_hash_form.empty?
        return ret
      end
      
      sorted_dsl_hash_form = dsl_hash_form.keys.map{|x|x.to_s}.sort().inject(SimpleOrderedHash.new()) do |h,k|
        h.merge(k => dsl_hash_form[k])
      end
      ret.merge(:component_modules => sorted_dsl_hash_form)
    end

    class ComponentTypeToCheck < Array
      def mapping_required?()
        find{|r|r[:required]}
      end
    end

    def get_needed_component_type_version_pairs(cmp_types)
      cmp_types.map do |cmp_type|
        version = ret_selected_version_string(cmp_type)
        {:component_type => cmp_type, :version => version, :version_field => ModuleBranch.version_field(version)}
      end
    end

    def get_component_type_to_template_mappings?(cmp_types,opts={})
      ret = Hash.new
      return ret if cmp_types.empty?
      # first put in ret info about component type and version
      ret = cmp_types.inject(Hash.new) do |h,cmp_type|
        version = ret_selected_version_string(cmp_type)
        h.merge(cmp_type => {:component_type => cmp_type, :version => version, :version_field => ModuleBranch.version_field(version)})
      end

      # get matching component template info and insert matches into ret
      Component::Template.get_matching_type_and_version(project_idh(),ret.values,opts).each do |cmp_template|
        ret[cmp_template[:component_type]].merge!(:component_template => cmp_template) 
      end
      ret
    end

    def ret_selected_version_string(component_type)
      if cmp_module_ref = component_modules[key(Component.module_name(component_type))]
        cmp_module_ref.version_string()
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
