module DTK; class Assembly
  class Template < self
    r8_nested_require('template','factory')

    def stage(target,assembly_name=nil)
      override_attrs = Hash.new
      override_attrs[:display_name] = assembly_name if assembly_name
      clone_opts = {:ret_new_obj_with_cols => [:id,:type]}
      new_assembly_obj = nil
      Transaction do
        new_assembly_obj = target.clone_into(self,override_attrs,clone_opts)
      end
      new_assembly_obj
    end

    ### standard get methods
    def get_nodes(opts={})
      self.class.get_nodes([id_handle()],opts)
    end
    def self.get_nodes(assembly_idhs,opts={})
      ret = Array.new
      return ret if assembly_idhs.empty?()
      sp_hash = {
        :cols => opts[:cols]||[:id, :group_id, :display_name],
        :filter => [:oneof, :assembly_id, assembly_idhs.map{|idh|idh.get_id()}]
      }
      node_mh = assembly_idhs.first.createMH(:node)
      get_objs(node_mh,sp_hash)
    end

    #TODO: this can be expensive call; may move to factoring in :component_module_refs relatsionship to what component_ref component_template_id is pointing to
    def self.get_augmented_component_refs(mh,opts={})
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:module_branch_id,:augmented_component_refs],
        :filter => [:and, [:eq, :type, "composite"], [:neq, :project_project_id, nil], opts[:filter]].compact
      }
      assembly_rows = get_objs(mh.createMH(:component),sp_hash)

      #look for version contraints which are on a per component module basis
      aug_cmp_refs_ndx_by_vc = Hash.new
      assembly_rows.each do |r|
        component_ref = r[:component_ref]
        unless component_type = component_ref[:component_type]||(r[:component_template]||{})[:component_type]
          Log.error("Component ref with id #{r[:id]}) does not have a compoennt type ssociated with it")
        else
          service_module_name = service_module_name(r[:component_type])
          pntr = aug_cmp_refs_ndx_by_vc[service_module_name]
          unless pntr 
            module_branch = mh.createIDH(:model_name => :module_branch, :id => r[:module_branch_id]).create_object()
            pntr = aug_cmp_refs_ndx_by_vc[service_module_name] = {
              :version_constraints => ComponentModuleRefs.create_and_reify?(module_branch,r[:component_module_refs])
            }
          end
          aug_cmp_ref = r[:component_ref].merge(r.hash_subset(:component_template,:node))
          (pntr[:aug_cmp_refs] ||= Array.new) << aug_cmp_ref
        end
      end
      set_matching_opts = Aux.hash_subset(opts,[:force_compute_template_id])
      aug_cmp_refs_ndx_by_vc.each_value do |r|
        r[:version_constraints].set_matching_component_template_info!(r[:aug_cmp_refs],set_matching_opts)
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

    #MOD_RESTRUCT: TODO: when deprecate self.list__library_parent(mh,opts={}), sub .list__project_parent for this method
    def self.list(mh,opts={})
      if project_id = opts[:project_idh]
        ndx_ret = list__library_parent(mh,opts).inject(Hash.new) do |h,r|
          ndx = version_display_name(r[:display_name],nil)
          h.merge(ndx => r)
        end
        list__project_parent(mh,opts).each do |r|
          ndx = version_display_name(r[:display_name],r[:version])
          ndx_ret[ndx] ||= r
        end
        ndx_ret.values.sort{|a,b|a[:display_name] <=> b[:display_name]}
      else
        list__library_parent(mh,opts)
      end
    end

    def self.get(mh,opts={})
      if project_id = opts[:project_idh]
        ndx_ret = list__library_parent(mh,opts).inject(Hash.new){|h,r|h.merge(r[:id] => r)}
        get__project_parent(mh,opts).each{|r|ndx_ret[r[:id]] ||= r}
        ndx_ret.values
      else
        get__library_parent(mh,opts)
      end
    end

    def self.get__project_parent(mh,opts={})
      sp_hash = {
        :cols => opts[:cols] || [:id, :group_id,:display_name,:component_type,:module_branch_id,:module_branch],
        :filter => [:and, [:eq, :type, "composite"], 
                    opts[:project_idh] ? [:eq,:project_project_id,opts[:project_idh].get_id()] : [:neq, :project_project_id,nil],
                    opts[:filter]
                   ].compact
      }
      ret = get_objs(mh.createMH(:component),sp_hash)
      #TODO: may instead make sure that version in assembly is set
      ret.each{|r|r[:version] ||= (r[:module_branch]||{})[:version]}
      ret
    end

    def self.list__project_parent(assembly_mh,opts={})
      opts = opts.merge(:cols => [:id, :group_id,:display_name,:component_type,:module_branch_id,:module_branch,list_virtual_column?(opts[:detail_level])].compact)
      assembly_rows = get__project_parent(assembly_mh,opts)
      if opts[:detail_level] == "attributes"
        attr_rows = get_component_attributes(assembly_mh,assembly_rows)
        list_aux(assembly_rows,attr_rows,opts)
      else
        list_aux__simple(assembly_rows,opts)
      end
    end
    #MOD_RESTRUCT: TODO: deprecate two below for above
    def self.list__library_parent(assembly_mh,opts={})
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:module_branch_id,list_virtual_column?(opts[:detail_level])].compact,
        :filter => [:and, [:eq, :type, "composite"], [:neq, :library_library_id, nil], opts[:filter]].compact
      }
      assembly_rows = get_objs(assembly_mh,sp_hash)
      if opts[:detail_level] == "attributes"
        attr_rows = get_component_attributes(assembly_mh,assembly_rows)
        list_aux(assembly_rows,attr_rows,opts)
      else
        list_aux__simple(assembly_rows,opts)
      end
    end
    def self.get__library_parent(mh,opts={})
      sp_hash = {
        :cols => opts[:cols] || [:id, :group_id,:display_name,:component_type],
        :filter => [:and, [:eq, :type, "composite"], [:neq, :library_library_id, nil], opts[:filter]].compact
      }
      get_objs(mh.createMH(:component),sp_hash)
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
        #TODO: hack to create a Assembly object (as opposed to row which is component); should be replaced by having 
        #get_objs do this (using possibly option flag for subtype processing)
        pntr = ndx_ret[r[:id]] ||= r.id_handle.create_object().merge(:display_name => pretty_print_name(r,pp_opts),:ndx_nodes => Hash.new)
        pntr.merge!(:module_branch_id => r[:module_branch_id]) if r[:module_branch_id]
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
        el = r.slice(:id,:display_name,:module_branch_id,:version)
        include_nodes ? el.merge(:nodes => r[:ndx_nodes].values) : el
      end
      opts[:no_sorting] ? unsorted : unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    def self.create_from_instance(project,node_idhs,assembly_name,service_module_name,icon_info=nil,version=nil)
      project_idh = project.id_handle()
      #1) get a content object, 2) modify, and 3) persist
      port_links,dangling_links = Node.get_conn_port_links(node_idhs)
      #TODO: raise error to user if dangling link
      Log.error("dangling links #{dangling_links.inspect}") unless dangling_links.empty?

      service_module_branch = ServiceModule.get_workspace_module_branch(project,service_module_name,version)

      assembly_factory = Factory.create_container_for_clone(project_idh,assembly_name,service_module_name,service_module_branch,icon_info)
      ws_branches = ModuleBranch.get_component_workspace_branches(node_idhs)
      assembly_factory.add_content_for_clone!(project_idh,node_idhs,port_links,ws_branches)
      assembly_factory.create_assembly_template(project_idh,service_module_branch)
    end

    def self.delete_and_ret_module_repo_info(assembly_idh)
      #first delete the dsl files
      module_repo_info = ServiceModule.delete_assembly_dsl?(assembly_idh)
      #need to explicitly delete nodes, but not components since node's parents are not the assembly, while component's parents are the nodes
      #do not need to delete port links which use a cascade foreign key
      delete_assemblies_nodes([assembly_idh])
      delete_instance(assembly_idh)
      module_repo_info
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

      return components.flatten
    end

    def self.exists?(project_idh,service_module_name,template_name)
      component_type = component_type(service_module_name,template_name)
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :component_type, component_type], [:eq, :project_project_id, project_idh.get_id()]]
      }
      get_obj(project_idh.createMH(:component),sp_hash)
    end
    #MOD_RESTRUCT: TODO: when deprecate library parent forms replace this by project parent forms
        def self.check_valid_id(model_handle,id)
      begin
        check_valid_id__library_parent(model_handle,id)
       rescue ErrorIdInvalid 
        check_valid_id__project_parent(model_handle,id)
      end
    end
    def self.name_to_id(model_handle,name)
      begin
        name_to_id__library_parent(model_handle,name)
       rescue ErrorNameDoesNotExist
        name_to_id__project_parent(model_handle,name)
      end
    end

    def self.check_valid_id__project_parent(model_handle,id)
      filter =
        [:and,
         [:eq, :id, id],
         [:eq, :type, "composite"],
         [:neq, :project_project_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end

    def self.name_to_id__project_parent(model_handle,name)
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
    #MOD_RESTRUCT: deprecate below for above
    def self.check_valid_id__library_parent(model_handle,id)
      filter =
        [:and,
         [:eq, :id, id],
         [:eq, :type, "composite"],
         [:neq, :library_library_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end

    def self.name_to_id__library_parent(model_handle,name)
      parts = name.split("/")
      augmented_sp_hash = 
        if parts.size == 1
          {:cols => [:id,:component_type],
           :filter => [:and,
                      [:eq, :component_type, pp_name_to_component_type(parts[0])],
                      [:eq, :type, "composite"],
                      [:neq, :library_library_id, nil]]
          }
        elsif parts.size == 2
          {:cols => [:id,:component_type,:library],
           :filter => [:and,
                      [:eq, :component_type, pp_name_to_component_type(parts[1])],
                      [:eq, :type, "composite"]],
           :post_filter => lambda{|r|r[:library][:display_name] ==  parts[0]}
          }
      else
        raise ErrorNameInvalid.new(name,pp_object_type())
      end
      name_to_id_helper(model_handle,name,augmented_sp_hash)
    end

     #returns [service_module_name,assembly_name]
    def self.parse_component_type(component_type)
      component_type.split(ModuleTemplateSep)
    end

    def self.get_component_attributes(assembly_mh,template_assembly_rows,opts={})
      #get attributes on templates (these are defaults)
      ret = get_default_component_attributes(assembly_mh,template_assembly_rows,opts)

      #get attribute overrides
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

    #TODO: probably move to Assembly
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
#TODO: hack to get around error in /home/dtk/server/system/model.r8.rb:31:in `const_get
AssemblyTemplate = Assembly::Template
end
