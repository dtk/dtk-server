module DTK
  class ModuleRefs
    r8_nested_require('module_refs', 'mixin')
    r8_nested_require('module_refs', 'parse')
    r8_nested_require('module_refs', 'component_dsl_form')
    r8_nested_require('module_refs', 'matching_templates')
    r8_nested_require('module_refs', 'tree')
    r8_nested_require('module_refs', 'lock')
    include MatchingTemplatesMixin

    attr_reader :parent, :component_modules
    def initialize(parent, content_hash_form, opts = {})
      @parent = parent
      @component_modules =  opts[:content_hash_form_is_reified] ?
        content_hash_form :
        Parse.reify_content(parent.model_handle(:model_ref), content_hash_form)
    end
    private :initialize

    # This finds module refs that matches branches
    def self.get_multiple_component_module_refs(branches)
      ndx_branches = branches.inject({}) { |h, r| h.merge(r[:id] => r) }
      ModuleRef.get_ndx_component_module_ref_arrays(branches).map do |(branch_id, cmr_array)|
        content_hash_content = cmr_array.inject({}) { |h, r| h.merge(key(r[:module_name]) => r) }
        new(ndx_branches[branch_id], content_hash_content)
      end
    end
    def self.get_component_module_refs(branch)
      content_hash_content = ModuleRef.get_component_module_ref_array(branch).inject({}) do |h, r|
        h.merge(key(r[:module_name]) => r)
      end
      new(branch, content_hash_content)
    end

    # returns true if an update made; this updates the ruby object
    # each element in the array cmp_modules_with_namespaces
    # is a component module object with the added field :namespace_name
    # TODO: DTK-2046
    # make change here so argument has external_ref info; so might pass in as argument module_ref objects
    # This might require the persistent module refs to be there
    def update_object_if_needed!(cmp_modules_with_namespaces)
      ret = false
      cmp_modules_with_namespaces.each do |cmp_mod|
        [:display_name, :namespace_name].each do |key|
          fail Error.new("Unexpected that cmp_modules_with_namespaces element does not have key: #{key}") unless cmp_mod[key]
        end
        cmp_mod_name = cmp_mod[:display_name]
        unless component_module_ref?(cmp_mod_name)
          add_or_set_component_module_ref(cmp_mod_name, namespace_info: cmp_mod[:namespace_name])
          ret = true
        end
      end
      ret
    end

    # serializes and saves object to repo
    def serialize_and_save_to_repo?(opts = {})
      dsl_hash_form = dsl_hash_form()
      if !dsl_hash_form.empty? || opts[:ambiguous] || opts[:possibly_missing] || opts[:create_empty_module_refs]
        meta_filename_path = meta_filename_path()
        @parent.serialize_and_save_to_repo?(meta_filename_path, dsl_hash_form, nil, opts)
      end
    end

    def matching_component_module_namespace?(cmp_module_name)
      if module_ref = component_module_ref?(key(cmp_module_name))
        module_ref.namespace()
      end
    end

    def version_objs_indexed_by_modules
      ret = {}
      component_modules.each_pair do |mod, cmr|
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
      filter = [:oneof, :id, assembly_templates.map { |r| r[:id] }]
      opts = {
        filter: filter,
        component_module_refs: self,
        force_compute_template_id: true
      }
      aug_cmp_refs = Assembly::Template.get_augmented_component_refs(component_module.model_handle(:component), opts)
      return if aug_cmp_refs.empty?
      cmp_ref_update_rows = aug_cmp_refs.map { |r| r.hash_subset(:id, :component_template_id) }
      Model.update_from_rows(component_module.model_handle(:component_ref), cmp_ref_update_rows)
    end

    def has_module_version?(cmp_module_name, version_string)
      if cmp_module_ref = component_module_ref?(cmp_module_name)
        cmp_module_ref.version_string() == version_string
      end
    end

    def include_module?(cmp_module_name)
      component_modules.key?(key(cmp_module_name))
    end

    def ret_service_module_info
      sp_hash = {
        cols: [:service_module_info]
      }
      get_obj(sp_hash)
    end

    def set_module_version(cmp_module_name, version)
      key = key(cmp_module_name)
      if cmr = @component_modules[key]
        cmr.set_module_version(version)
      else
        hash_content = {
          component_module: cmp_module_name,
          version_info: version
        }
        @component_modules[key] = ModuleRef.reify(@parent.model_handle, hash_content)
      end
      ModuleRef.update(:create_or_update, @parent, @component_modules.values)
    end

    def update
      module_ref_hash_array = @component_modules.map do |(key, hash)|
        el = hash
        unless hash[:module_name]
          el = el.merge(module_name: key.to_s)
        end
        unless hash[:module_type]
          el = el.merge(module_type: 'component')
        end
        el
      end
      ModuleRef.create_or_update(@parent, module_ref_hash_array)
    end

    def self.clone_component_module_refs(base_branch, new_branch)
      cmrs = get_component_module_refs(base_branch)
      ModuleRef.create_or_update(new_branch, cmrs.component_modules.values)
    end

    private

   def self.update(parent, cmp_modules)
      ModuleRef.create_or_update(parent, cmp_modules.values)
    end

    def component_module_ref?(cmp_module_name)
      @component_modules[key(cmp_module_name)]
    end

    def add_or_set_component_module_ref(cmp_module_name, mod_ref_hash)
      @component_modules[key(cmp_module_name)] = ModuleRef.reify(@parent.model_handle(), mod_ref_hash)
    end

    def self.key(el)
      el.to_sym
    end
    def key(el)
      self.class.key(el)
    end

    def self.isa_dsl_filename?(path)
      path == meta_filename_path()
    end
    def meta_filename_path
      self.class.meta_filename_path()
    end
    def self.meta_filename_path
      ServiceModule::DSLParser.default_rel_path?(:component_module_refs) ||
        fail(Error.new('Unexpected that cannot compute a meta_filename_path for component_module_refs'))
    end

    def dsl_hash_form
      ret = SimpleOrderedHash.new()
      dsl_hash_form = {}
      component_modules.each_pair do |cmp_module_name, cmr|
        hf = cmr.dsl_hash_form()
        dsl_hash_form[cmp_module_name.to_s] = hf unless hf.empty?
      end

      if dsl_hash_form.empty?
        return ret
      end

      sorted_dsl_hash_form = dsl_hash_form.keys.map(&:to_s).sort().inject(SimpleOrderedHash.new()) do |h, k|
        h.merge(k => dsl_hash_form[k])
      end
      ret.merge(component_modules: sorted_dsl_hash_form)
    end

    class ComponentTypeToCheck < Array
      def mapping_required?
        find { |r| r[:required] }
      end
    end

    def project_idh
      return @project_idh if @project_idh
      unless service_id = @parent.get_field?(:service_id)
        fail Error.new('Cannot find project from parent object')
      end
      service_module = @parent.model_handle(:service_module).createIDH(id: service_id).create_object()
      unless project_id = service_module.get_field?(:project_project_id)
        fail Error.new('Cannot find project from parent object')
      end
      @parent.model_handle(:project).createIDH(id: project_id)
    end
  end
end
