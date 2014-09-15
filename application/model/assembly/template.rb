module DTK; class Assembly
  class Template < self
    r8_nested_require('template','factory')

    def get_objs(sp_hash,opts={})
      super(sp_hash,opts.merge(:model_handle => model_handle().createMH(:assembly_template)))
    end
    def self.get_objs(mh,sp_hash,opts={})
      if mh[:model_name] == :assembly_template
        get_these_objs(mh,sp_hash,opts)
      else
        super
      end
    end

    def self.create_from_id_handle(idh)
      idh.create_object(:model_name => :assembly_template)
    end

    def stage(target,opts={})
      assembly_name = opts[:assembly_name]
      service_module = get_service_module()
      is_dsl_parsed = service_module.dsl_parsed?()
      raise ErrorUsage.new("You are not allowed to stage service from service-module ('#{service_module}') that has dsl parsing errors") unless is_dsl_parsed

      override_attrs = Hash.new
      if assembly_name
        override_attrs[:display_name] = assembly_name
      end
      clone_opts = {:ret_new_obj_with_cols => [:id,:type]}
      if settings = opts[:service_settings]
        clone_opts.merge!(:service_settings => settings)
      end
      new_assembly_obj = nil
      Transaction do
        new_assembly_obj = target.clone_into(self,override_attrs,clone_opts)
      end
      Assembly::Instance.create_subclass_object(new_assembly_obj)
    end

    def self.create_or_update_from_instance(project,assembly_instance,service_module_name,assembly_template_name,opts={})
      default_namespace = Namespace.default_namespace_name
      is_workspace = Workspace.is_workspace?(assembly_instance)
      # if namespace is not provided by user there are two options
      # 1. if this method is called from workspace then use default namespace
      # 2. if called from service instance then use namespace from service-module that instance belongs to
      namespace = ((is_workspace && default_namespace) ? default_namespace : assembly_instance.get_namespace()[:display_name])
      opts.merge!(:namespace => namespace) unless opts[:namespace]

      service_module = Factory.get_or_create_service_module(project,service_module_name,opts)
      Factory.create_or_update_from_instance(assembly_instance,service_module,assembly_template_name,opts)
      service_module.update(:dsl_parsed => true)

      service_module
    end

    ### standard get methods
    def get_nodes(opts={})
      self.class.get_nodes([id_handle()],opts)
    end
    def self.get_nodes(assembly_idhs,opts={})
      ret = Array.new
      return ret if assembly_idhs.empty?()
      sp_hash = {
        :cols => opts[:cols]||[:id, :group_id, :display_name, :assembly_id],
        :filter => [:oneof, :assembly_id, assembly_idhs.map{|idh|idh.get_id()}]
      }
      node_mh = assembly_idhs.first.createMH(:node)
      get_objs(node_mh,sp_hash)
    end

    def self.get_ndx_assembly_names_to_ids(project_idh,service_module,assembly_names)
      ndx_assembly_refs = assembly_names.inject(Hash.new){|h,n|h.merge(n => service_module.assembly_ref(n))}
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:ref],
        :filter => [:and,[:eq,:project_project_id,project_idh.get_id],[:oneof,:ref,ndx_assembly_refs.values]]
      }
      assembly_templates = get_objs(project_idh.createMH(:component),sp_hash,:keep_ref_cols => true)
      ndx_ref_ids = assembly_templates.inject(Hash.new){|h,r|h.merge(r[:ref] => r[:id])}
      ndx_assembly_refs.inject(Hash.new) do |h,(name,ref)|
        id = ndx_ref_ids[ref]
        id ? h.merge(name => id) : h
      end
    end

    def self.augment_with_namespaces!(assembly_templates)
      ndx_namespaces = get_ndx_namespaces(assembly_templates)
      assembly_templates.each do |a|
        if namespace = ndx_namespaces[a[:id]]
          a[:namespace] ||= namespace
        end
      end
      assembly_templates
    end

    # indexed by assembly_template id
    def self.get_ndx_namespaces(assembly_templates)
      ret = Hash.new
      return ret if assembly_templates.empty?
      sp_hash = {
        :cols =>  [:id,:group_id,:display_name,:module_branch_id,:assembly_template_namespace_info],
        :filter => [:oneof,:id,assembly_templates.map{|a|a.id()}]
      }
      mh = assembly_templates.first.model_handle()
      get_objs(mh,sp_hash).inject(Hash.new) do |h,r|
        h.merge(r[:id] => r[:namespace])
      end
    end
    private_class_method :get_ndx_namespaces

    def get_settings(opts={})
      sp_hash = {
        :cols => opts[:cols]||ServiceSetting.common_columns(),
        :filter => [:eq, :component_component_id, id()]
      }
      service_setting_mh = model_handle(:service_setting)
      Model.get_objs(service_setting_mh,sp_hash)
    end

    def self.get_augmented_component_refs(mh,opts={})
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:module_branch_id,:augmented_component_refs],
        :filter => [:and, [:eq, :type, "composite"], [:neq, :project_project_id, nil], opts[:filter]].compact
      }
      assembly_rows = get_objs(mh.createMH(:component),sp_hash)

      # look for version contraints which are on a per component module basis
      aug_cmp_refs_ndx_by_vc = Hash.new
      assembly_rows.each do |r|
        component_ref = r[:component_ref]
        unless component_type = component_ref[:component_type]||(r[:component_template]||{})[:component_type]
          Log.error("Component ref with id #{r[:id]}) does not have a component type associated with it")
        else
          service_module_name = service_module_name(r[:component_type])
          pntr = aug_cmp_refs_ndx_by_vc[service_module_name]
          unless pntr
            component_module_refs = opts[:component_module_refs] || ModuleRefs.get_component_module_refs(mh.createIDH(:model_name => :module_branch, :id => r[:module_branch_id]).create_object())

            pntr = aug_cmp_refs_ndx_by_vc[service_module_name] = {
              :component_module_refs => component_module_refs
            }
          end
          aug_cmp_ref = r[:component_ref].merge(r.hash_subset(:component_template,:node))
          (pntr[:aug_cmp_refs] ||= Array.new) << aug_cmp_ref
        end
      end
      set_matching_opts = Aux.hash_subset(opts,[:force_compute_template_id])
      aug_cmp_refs_ndx_by_vc.each_value do |r|
        r[:component_module_refs].set_matching_component_template_info?(r[:aug_cmp_refs],set_matching_opts)
      end
      aug_cmp_refs_ndx_by_vc.values.map{|r|r[:aug_cmp_refs]}.flatten
    end
    ### end: standard get methods

    class << self
     private
      def service_module_name(component_type_field)
        component_type_field.gsub(/__.+$/,'')
      end
    end

    def self.list(assembly_mh,opts={})
      assembly_mh = assembly_mh.createMH(:assembly_template) # to insure right mh type
      opts = opts.merge(:cols => [:id, :group_id,:display_name,:component_type,:module_branch_id,:service_module,list_virtual_column?(opts[:detail_level])].compact)
      assembly_rows = get(assembly_mh,opts)
      if opts[:detail_level] == "attributes"
        attr_rows = get_component_attributes(assembly_mh,assembly_rows)
        list_aux(assembly_rows,attr_rows,opts)
      else
        list_aux__simple(assembly_rows,opts)
      end
    end

    def self.get(mh,opts={})
      sp_hash = {
        :cols => opts[:cols] || [:id, :group_id,:display_name,:component_type,:module_branch_id,:service_module],
        :filter => [:and, [:eq, :type, "composite"],
                    opts[:project_idh] ? [:eq,:project_project_id,opts[:project_idh].get_id()] : [:neq, :project_project_id,nil],
                    opts[:filter]
                   ].compact
      }
      ret = get_these_objs(mh,sp_hash,:keep_ref_cols => true)
      ret.each{|r|r[:version] ||= (r[:module_branch]||{})[:version]}
      ret
    end

    def self.list_virtual_column?(detail_level=nil)
      if detail_level.nil?
        nil
      elsif detail_level == "nodes"
        :template_stub_nodes
      else
        raise Error.new("not implemented list_virtual_column at detail level (#{detail_level})")
      end
    end

    def self.list_aux__simple(assembly_rows,opts={})
      ndx_ret = Hash.new
      if opts[:detail_level] == "components"
        raise Error.new("list assembly templates at component level not treated")
      end
      include_nodes = ["nodes"].include?(opts[:detail_level])
      pp_opts = Aux.hash_subset(opts,[:no_module_prefix,:version_suffix])
      assembly_rows.each do |r|
        # TODO: hack to create a Assembly object (as opposed to row which is component); should be replaced by having
        # get_objs do this (using possibly option flag for subtype processing)
        pntr = ndx_ret[r[:id]] ||= r.id_handle.create_object().merge(:display_name => pretty_print_name(r,pp_opts),:ndx_nodes => Hash.new)
        pntr.merge!(:module_branch_id => r[:module_branch_id]) if r[:module_branch_id]
        # TODO: should replace with something more robust to find namespace
        if namespace = Namespace.namespace_from_ref?(r[:service_module][:ref])
          pntr.merge!(:namespace => namespace)
        end

        if version = pretty_print_version(r)
          pntr.merge!(:version => version)
        end
        next unless include_nodes
        node_id = r[:node][:id]
        unless node = pntr[:ndx_nodes][node_id]
          node = pntr[:ndx_nodes][node_id] = {
            :node_name => r[:node][:display_name],
            :node_id => node_id
          }
          node[:external_ref] = r[:node][:external_ref] if r[:node][:external_ref]
          node[:os_type] = r[:node][:os_type] if r[:node][:os_type]
        end
      end

      unsorted = ndx_ret.values.map do |r|
        el = r.slice(:id,:display_name,:module_branch_id,:version,:namespace)
        include_nodes ? el.merge(:nodes => r[:ndx_nodes].values) : el
      end
      opts[:no_sorting] ? unsorted : unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    def self.pretty_print_name(assembly,opts={})
      ret =
        if cmp_type = assembly.get_field?(:component_type)
          if opts[:no_module_prefix]
            cmp_type.gsub(/^.+__/,"")
          else
            cmp_type.gsub(/__/,"::")
          end
        else
          assembly.get_field?(:display_name)
        end

      if opts[:version_suffix]
        if version = pretty_print_version(assembly)
          ret << "-v#{version}"
        end
      end
      if opts[:include_namespace]
        unless namespace_name = (assembly[:namespace]||{})[:display_name]
          Log.error("Unexpected that opts[:include_namespace] is truue and no namespace object in assembly")
          return ret
        end
        ret = Namespace.join_namespace(namespace_name, ret)
      end
      ret
    end

    def self.delete_and_ret_module_repo_info(assembly_idh)
      # first delete the dsl files
      module_repo_info = ServiceModule.delete_assembly_dsl?(assembly_idh)
      # need to explicitly delete nodes, but not components since node's parents are not the assembly, while component's parents are the nodes
      # do not need to delete port links which use a cascade foreign key
      delete_model_objects(assembly_idh)
      module_repo_info
    end

    def self.delete_model_objects(assembly_idh)
      delete_assemblies_nodes([assembly_idh])
      delete_instance(assembly_idh)
    end

    def self.delete_assemblies_nodes(assembly_idhs)
      ret = Array.new
      return ret if assembly_idhs.empty?
      node_idhs = get_nodes(assembly_idhs).map{|n|n.id_handle()}
      Model.delete_instances(node_idhs)
    end

    def info_about(about, opts=Opts.new)
      cols = post_process = nil
      order = proc{|a,b|a[:display_name] <=> b[:display_name]}
      ret = nil
      case about
       when :components
        aug_component_refs = self.class.get_augmented_component_refs(model_handle,:filter => [:eq,:id,id()])
        ret = aug_component_refs.map do |r|
          cmp_template = r[:component_template]
          display_name = "#{r[:node][:display_name]}/#{r.display_name_print_form()}"
          version = ModuleBranch.version_from_version_field(cmp_template[:version])
          cmp_template.hash_subset(:id).merge(:display_name => display_name, :version => version)
        end
        return ret.sort(&order)
       when :nodes
        cols = [:node_templates]
        post_process = proc do |r|
          binding = r[:node_binding]
          binding_fields = binding.hash_subset(:os_type,{:display_name => :template_name})
          common_fields = binding.ret_common_fields_or_that_varies()
          {:type=>"ec2_image", :image_id=>:varies, :region=>:varies, :size=>"m1.medium"}
          common_fields_to_add = Aux::hash_subset(common_fields,[{:type => :template_type},:image_id,:size,:region]).reject{|k,v|v == :varies}
          binding_fields.merge!(common_fields_to_add)
          r[:node].hash_subset(:id,:display_name).merge(binding_fields)
        end
      end
      unless cols
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
      return rer if ret

      rows = get_objs(:cols => cols)
      ret = post_process ? rows.map{|r|post_process.call(r)} : rows
      order ? ret.sort(&order) : ret
    end

    def self.list_modules(assembly_templates)
      components = []
      assembly_templates.each do |assembly|
        components << assembly.info_about(:components)
      end
      components.flatten
    end

    def self.check_valid_id(model_handle,id)
      filter =
        [:and,
         [:eq, :id, id],
         [:eq, :type, "composite"],
         [:neq, :project_project_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end
    def self.name_to_id(model_handle,name)
      parts = name.split("/")
      augmented_sp_hash =
        if parts.size == 1
          {:cols => [:id,:component_type],
           :filter => [:and,
                      [:eq, :component_type, pp_name_to_component_type(parts[0])],
                      [:eq, :type, "composite"],
                      [:neq, :project_project_id, nil]]
          }
      else
        raise ErrorNameInvalid.new(name,pp_object_type())
      end
      name_to_id_helper(model_handle,name,augmented_sp_hash)
    end

    def self.get_service_module?(project,service_module_name,namespace)
      ret = nil
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:namespace],
        :filter => [:eq,:display_name,service_module_name]
      }
      get_objs(project.model_handle(:service_module),sp_hash).find{|r|r[:namespace][:display_name] == namespace}
    end

     # returns [service_module_name,assembly_name]
    def self.parse_component_type(component_type)
      component_type.split(ModuleTemplateSep)
    end

    def self.get_component_attributes(assembly_mh,template_assembly_rows,opts={})
      # get attributes on templates (these are defaults)
      ret = get_default_component_attributes(assembly_mh,template_assembly_rows,opts)

      # get attribute overrides
      sp_hash = {
        :cols => [:id,:display_name,:attribute_value,:attribute_template_id],
        :filter => [:oneof, :component_ref_id,template_assembly_rows.map{|r|r[:component_ref][:id]}]
      }
      attr_override_rows = Model.get_objs(assembly_mh.createMH(:attribute_override),sp_hash)
      unless attr_override_rows.empty?
        ndx_attr_override_rows = attr_override_rows.inject(Hash.new) do |h,r|
          h.merge(r[:attribute_template_id] => r)
        end
        ret.each do |r|
          if override = ndx_attr_override_rows[r[:id]]
            r.merge!(:attribute_value => override[:attribute_value], :is_instance_value => true)
          end
        end
      end
      ret
    end

    def display_name_print_form()
      pp_display_name(get_field?(:component_type))
    end

    # TODO: probably move to Assembly
    def model_handle(mn=nil)
      super(mn||:component)
    end

   private
    def pp_display_name(component_type)
      component_type.gsub(Regexp.new(ModuleTemplateSep),"::")
    end
    def self.pp_name_to_component_type(pp_name)
      pp_name.gsub(/::/,ModuleTemplateSep)
    end
     def self.component_type(service_module_name,template_name)
       "#{service_module_name}#{ModuleTemplateSep}#{template_name}"
     end

    ModuleTemplateSep = "__"

  end
end
# TODO: hack to get around error in /home/dtk/server/system/model.rb:31:in `const_get
AssemblyTemplate = Assembly::Template
end
