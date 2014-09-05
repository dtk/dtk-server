module DTK
  class ModuleRefs 
    r8_nested_require('module_refs','mixin')
    r8_nested_require('module_refs','parse')
    r8_nested_require('module_refs','matching_templates')
    include MatchingTemplatesMixin

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
        :force_compute_template_id => true
      }
      aug_cmp_refs = Assembly::Template.get_augmented_component_refs(component_module.model_handle(:component),opts)
      return if aug_cmp_refs.empty?
      cmp_ref_update_rows = aug_cmp_refs.map{|r|r.hash_subset(:id,:component_template_id)}
      Model.update_from_rows(component_module.model_handle(:component_ref),cmp_ref_update_rows)
    end


    attr_reader :component_modules
                                                                          
    def has_module_version?(cmp_module_name,version_string)
      if cmp_module_ref = component_module_ref?(cmp_module_name)
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
      get_obj(sp_hash)
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
    def component_module_ref?(cmp_module_name)
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

    def self.meta_filename_path()
      unless @meta_filename_path ||= ServiceModule::DSLParser.default_rel_path?(:component_module_refs)
        raise Error.new("Unexpected that cannot compute a meta_filename_path for component_module_refs")
      end
      @meta_filename_path
    end

    def self.update(parent,cmp_modules)
      ModuleRef.update(:create_or_update,parent,cmp_modules.values)
    end

    def self.serialize_and_save_to_repo(parent)
      meta_filename_path = meta_filename_path()
      parent.serialize_and_save_to_repo(meta_filename_path,dsl_hash_form(parent))
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
