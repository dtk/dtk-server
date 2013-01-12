module DTK; class Assembly
  class Template < self
    ### standard get methods
    def self.get_nodes(assembly_idhs)
      ret = Array.new
      return ret if assembly_idhs.empty?()
      sp_hash = {
        :cols => [:id, :group_id, :display_name],
        :filter => [:oneof, :id, assembly_idhs.map{|idh|idh.get_id()}]
      }
      node_mh = assembly_idhs.first.createMH(:node)
      get_objs(node_mh,sp_hash)
    end

    #TODO: this can be expensive call; may move to factoring in :module_version_constraints relatsionship to what component_ref component_template_id is pointing to
    def self.get_augmented_component_refs(mh,opts={})
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:module_branch_id,:augmented_component_refs],
        :filter => [:and, [:eq, :type, "composite"], [:neq, :project_project_id, nil], opts[:filter]].compact
      }
      aug_cmp_refs = get_objs(mh.createMH(:component),sp_hash)

      #look for version contraints which are on a per component module basis
      aug_cmp_refs_ndx_by_vc = Hash.new
      aug_cmp_refs.each do |r|
        unless component_type = (r[:component_ref]||{})[:component_type]||(r[:component_template]||{})[:component_type]
          Log.error("Component ref with id #{r[:id]}) does not have a compoennt type ssociated with it")
        else
          service_module_name = service_module_name(r[:component_type])
          pntr = aug_cmp_refs_ndx_by_vc[service_module_name]
          unless pntr 
            module_branch = mh.createIDH(:model_name => :module_branch, :id => r[:module_branch_id]).create_object()
            pntr = aug_cmp_refs_ndx_by_vc[service_module_name] = {
              :version_constraints => ModuleVersionConstraints.create_and_reify?(module_branch,r[:module_version_constraints])
            }
          end
          (pntr[:aug_cmp_refs] ||= Array.new) << r
        end
      end
      aug_cmp_refs_ndx_by_vc.each_value do |r|
        r[:version_constraints].set_matching_component_template_info!(r[:aug_cmp_refs])
      end
      aug_cmp_refs
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
        ndx_ret = list__library_parent(mh,opts).inject(Hash.new){|h,r|h.merge(r[:display_name] => r)}
        list__project_parent(mh,opts[:project_idh]).each{|r|ndx_ret[r[:display_name]] ||= r}
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
        list__library_parent(mh,opts)
      end
    end

    def self.get__project_parent(mh,opts={})
      sp_hash = {
        :cols => [:id, :group_id,:display_name,:component_type],
        :filter => [:and, [:eq, :type, "composite"], 
                    opts[:project_idh] ? [:eq,:project_project_id,opts[:project_idh].get_id()] : [:neq, :project_project_id,nil],
                    opts[:filter]
                   ].compact
      }
      get_objs(mh.createMH(:component),sp_hash)
    end

    def self.list__project_parent(assembly_mh,opts={})
      #TODO: rewrite to use this when at certain detail level
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:module_branch_id,:template_nodes_and_cmps_summary],
        :filter => [:and, [:eq, :type, "composite"], [:neq, :project_project_id, nil], opts[:filter]].compact
      }
      assembly_rows = get_objs(assembly_mh,sp_hash)
      get_attrs = (opts[:detail_level] and [opts[:detail_level]].flatten.include?("attributes")) 
      attr_rows = get_attrs ? get_component_attributes(assembly_mh,assembly_rows) : []
      list_aux(assembly_rows,attr_rows,opts)
    end
    #MOD_RESTRUCT: TODO: deprecate below for above
    def self.list__library_parent(assembly_mh,opts={})
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:module_branch_id,:template_nodes_and_cmps_summary],
        :filter => [:and, [:eq, :type, "composite"], [:neq, :library_library_id, nil], opts[:filter]].compact
      }
      assembly_rows = get_objs(assembly_mh,sp_hash)
      get_attrs = (opts[:detail_level] and [opts[:detail_level]].flatten.include?("attributes")) 
      attr_rows = get_attrs ? get_component_attributes(assembly_mh,assembly_rows) : []
      list_aux(assembly_rows,attr_rows,opts)
    end

    def self.create_workspace_template(project,node_idhs,assembly_name,service_module_name,icon_info,version=nil)
      project_idh = project.id_handle()
      #1) get a content object, 2) modify, and 3) persist
      port_links,dangling_links = Node.get_conn_port_links(node_idhs)
      #TODO: raise error to user if dangling link
      Log.error("dangling links #{dangling_links.inspect}") unless dangling_links.empty?

      service_module_branch = ServiceModule.get_workspace_module_branch(project,service_module_name,version)

      assembly_ci = Content::Instance.create_container_for_clone(project_idh,assembly_name,service_module_name,service_module_branch,icon_info)
      ws_branches = ModuleBranch.get_component_workspace_branches(node_idhs)
      assembly_ci.add_content_for_clone!(project_idh,node_idhs,port_links,ws_branches)
      assembly_ci.create_assembly_template(project_idh,service_module_branch)
    end
    #MOD_RESTRUCT: TODO: deprecate below for above
    def self.create_library_template(library_idh,node_idhs,assembly_name,service_module_name,icon_info,version=nil)
      #first make sure that all referenced components have updated modules in the library
      ws_branches = ModuleBranch.get_component_workspace_branches(node_idhs)
      augmented_lib_branches = ModuleBranch.update_library_from_workspace?(ws_branches)

      #1) get a content object, 2) modify, and 3) persist
      port_links,dangling_links = Node.get_conn_port_links(node_idhs)
      #TODO: raise error to user if dangling link
      Log.error("dangling links #{dangling_links.inspect}") unless dangling_links.empty?

      service_module_branch = ServiceModule.get_library_module_branch(library_idh,service_module_name,version)

      assembly_ci =  Content::Instance.create_container_for_clone(library_idh,assembly_name,service_module_name,service_module_branch,icon_info)
      assembly_ci.add_content_for_clone!(library_idh,node_idhs,port_links,augmented_lib_branches)
      assembly_ci.create_assembly_template(library_idh,service_module_branch)
      #TODO: assembly_template_ws_item
      assembly_ci.synchronize_workspace_with_library_branch()
    end

    #TODO: assembly_template_ws_item
    #TODO:   assembly_idh parent is library
    def self.delete(assembly_idh)
      #first delete the dsl files
      ServiceModule.delete_assembly_dsl?(assembly_idh)
      #need to explicitly delete nodes, but not components since node's parents are not the assembly, while compoennt's parents are the nodes
      #do not need to delete port links which use a cascade foreign keyy
      delete_assemblies_nodes([assembly_idh])
      delete_instance(assembly_idh)
    end

    def self.delete_assemblies_nodes(assembly_idhs)
      ret = Array.new
      return ret if assembly_idhs.empty?
      node_idhs = get_nodes(assembly_idhs).map{|n|n.id_handle()}
      Model.delete_instances(node_idhs)    
    end

    def info_about(about)
      cols = post_process = nil
      order = proc{|a,b|a[:display_name] <=> b[:display_name]}
      ret = nil
      case about 
       when :components
        cols = [:template_nodes_and_cmps_summary]
        post_process = proc do |r|
          display_name = "#{r[:node][:display_name]}/#{pp_display_name(r[:nested_component][:display_name])}"
          r[:nested_component].hash_subset(:id).merge(:display_name => display_name)
        end
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

    def self.exists?(library_idh,service_module_name,template_name)
      component_type = component_type(service_module_name,template_name)
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :component_type, component_type], [:eq, :library_library_id, library_idh.get_id()]]
      }
      get_obj(library_idh.createMH(:component),sp_hash)
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

   private
    def pp_display_name(display_name)
      display_name.gsub(Regexp.new(ModuleTemplateSep),"::")
    end
    def self.pp_name_to_component_type(pp_name)
      pp_name.gsub(/::/,ModuleTemplateSep)
    end
     def self.component_type(service_module_name,template_name)
       "#{service_module_name}#{ModuleTemplateSep}#{template_name}"
     end

    ModuleTemplateSep = "__"

    #TODO: probably move to Assembly
    def model_handle(mn=nil)
      super(mn||:component)
    end
  end
end
#TODO: hack to get around error in /home/dtk/server/system/model.r8.rb:31:in `const_get
AssemblyTemplate = Assembly::Template
end
