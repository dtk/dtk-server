module DTK; class  Assembly
  class Instance < self
    r8_nested_require('instance','action')
    r8_nested_require('instance','violation')
    r8_nested_require('instance','service_link')
    r8_nested_require('instance','update')
    r8_nested_require('instance','list')
    r8_nested_require('instance','delete')
    r8_nested_require('instance','service_setting')
    include ViolationMixin
    include ServiceLinkMixin
    include ListMixin
    extend ListClassMixin
    include DeleteMixin
    extend DeleteClassMixin

    def get_objs(sp_hash,opts={})
      super(sp_hash,opts.merge(:model_handle => model_handle().createMH(:assembly_instance)))
    end

    def self.get_objs(mh,sp_hash,opts={})
      if mh[:model_name] == :assembly_instance
        get_these_objs(mh,sp_hash,opts)
      else
        super
      end
    end

    def self.create_from_id_handle(idh)
      idh.create_object(:model_name => :assembly_instance)
    end

    ### standard get methods
    def get_task_templates(opts={})
      sp_hash = {
        :cols => Task::Template.common_columns(),
        :filter => [:eq,:component_component_id,id()]
      }
      Model.get_objs(model_handle(:task_template),sp_hash)
    end

    def get_parent()
      Template.create_from_component(get_obj_helper(:instance_parent,:assembly_template))
    end

    def get_peer_component_instances(cmp_instance)
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_type],
        :filter => [:and,[:eq,:ancestor_id,cmp_instance.get_field?(:ancestor_id)],
                    [:eq,:assembly_id,id()],
                    [:neq,:id,cmp_instance.id()]]
      }
      Component::Instance.get_objs(model_handle(:component_instance),sp_hash)
    end

    def get_task_template(task_action=nil,opts={})
      task_action ||= Task::Template.default_task_action()
      sp_hash = {
        :cols => opts[:cols]||Task::Template.common_columns(),
        :filter => [:and,[:eq,:component_component_id,id()],
                    [:eq,:task_action,task_action]]
      }
      Model.get_obj(model_handle(:task_template),sp_hash)
    end

    def get_parents_task_template(task_action=nil)
      task_action ||= Task::Template.default_task_action()
      get_objs_helper(:parents_task_templates,:task_template).select{|r|r[:task_action]==task_action}.first
    end

    def get_task_template_serialized_content(task_action=nil,opts={})
      opts_task_gen = {:task_action => task_action,:dont_persist_generated_template => true}.merge(opts)
      action_types = opts[:action_types]||[:assembly,:node_centric]
      ret = Task::Template::ConfigComponents.get_or_generate_template_content(action_types,self,opts_task_gen)
      ret && ret.serialization_form()
    end

    def rename(assembly_mh, name, new_name)
      assembly_list = Assembly::Instance.list(assembly_mh)
      raise ErrorUsage.new("You are not allowed to use keyword '#{new_name}' as #{pp_object_type()} name") if new_name.to_s.eql?("workspace")

      assembly_list.each do |assembly|
        raise ErrorUsage.new("#{pp_object_type().cap} with name '#{new_name}' exists already") if assembly[:display_name].to_s.eql?(new_name)
      end

      update(:display_name => new_name)
    end

    def get_component_list(opts={})
      get_field?(:display_name)
      assembly_source = {:type => "assembly", :object => hash_subset(:id,:display_name)}
      rows = get_objs_helper(:instance_component_list,:nested_component,opts.merge(:augmented => true))
      Component::Instance.add_title_fields?(rows)
      ret = opts[:add_on_to]||opts[:seed]||Array.new
      rows.each{|r|ret << r.merge(:source => assembly_source)}
      ret
    end

    def get_augmented_node_attributes(filter_proc=nil)
      get_objs_helper(:node_attributes,:attribute,:filter_proc => filter_proc,:augmented => true)
    end

    def get_augmented_nested_component_attributes(filter_proc=nil)
      get_objs_helper(:instance_nested_component_attributes,:attribute,:filter_proc => filter_proc,:augmented => true)
    end

    def get_augmented_attribute_mappings()
      # TODO: once field assembly_id is always populated on attribute.link, can do simpler query
      ret = Array.new
      sp_hash = {
        :cols => [:id,:group_id],
        :filter => [:eq,:assembly_id,id()]
      }
      port_links = Model.get_objs(model_handle(:port_link),sp_hash)
      filter = [:or,[:oneof,:port_link_id,port_links.map{|r|r.id()}],[:eq,:assembly_id,id()]]
      AttributeLink.get_augmented(model_handle(:attribute_link),filter)
    end

    def get_service_add_ons()
      get_objs_helper(:service_add_ons_from_instance,:service_add_on)
    end

    def get_augmented_service_add_ons()
      get_objs_helper(:aug_service_add_ons_from_instance,:service_add_on,:augmented => true)
    end
    def get_augmented_service_add_on(add_on_name)
      filter_proc = lambda{|sao|sao[:service_add_on][:display_name] == add_on_name}
      get_obj_helper(:aug_service_add_ons_from_instance,:service_add_on,:filter_proc => filter_proc, :augmented => true)
    end

    def get_node?(filter)
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and,[:eq, :assembly_id, id()],filter]
      }
      rows = Model.get_objs(model_handle(:node),sp_hash)
      if rows.size > 1
        Log.error("Unexpected that more than one row returned for filter (#{filter.inspect})")
        return nil
      end
      rows.first
    end

    # TODO: rename to reflect that not including node group members, just node groups themselves and top level nodes
    # This is equivalent to saying that this does not return target_refs
    def self.get_nodes_simple(assembly_idhs,opts={})
      ret = Array.new
      return ret if assembly_idhs.empty?()
      sp_hash = {
        :cols => opts[:cols] || [:id,:display_name,:group_id,:type,:assembly_id],
        :filter => [:oneof,:assembly_id,assembly_idhs.map{|idh|idh.get_id()}]
      }
      node_mh = assembly_idhs.first.createMH(:node)
      ret = get_objs(node_mh,sp_hash)
      unless opts[:ret_subclasses]
        ret
      else
        ret.map do |r|
          r.is_node_group? ? r.id_handle().create_object(:model_name => :service_node_group).merge(r) : r
        end
      end
    end

    # TODO: rename to reflect that not including node group members, just node groups themselves and top level nodes
    # This is equivalent to saying that this does not return target_refs
    def get_nodes(*alt_cols)
      self.class.get_nodes([id_handle],*alt_cols)
    end
    def self.get_nodes(assembly_idhs,*alt_cols)
      ret = Array.new
      return ret if assembly_idhs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:node_node_id,:type],
        :filter => [:oneof, :assembly_id, assembly_idhs.map{|idh|idh.get_id()}]
      }
      ndx_nodes = Hash.new
      component_mh = assembly_idhs.first.createMH(:component)
      get_objs(component_mh,sp_hash).each do |cmp|
        ndx_nodes[cmp[:node_node_id]] ||= true
      end

      cols = ([:id,:display_name,:group_id] + alt_cols).uniq
      sp_hash = {
        :cols => cols,
        :filter => [:and, filter_out_target_refs(),
                          [:or,[:oneof, :id, ndx_nodes.keys],
                               #to catch nodes without any components
                               [:oneof, :assembly_id,assembly_idhs.map{|idh|idh.get_id()}]]
                   ]
      }
      node_mh = assembly_idhs.first.createMH(:node)
      get_objs(node_mh,sp_hash)
    end
    def self.filter_out_target_refs()
      @filter_out_target_ref ||= [:and] + Node::TargetRef.types.map{|t|[:neq, :type, t]}
    end
    private_class_method :filter_out_target_refs

    def get_leaf_nodes(opts={})
      get_nodes__expand_node_groups(opts.merge(:remove_node_groups=>true))
    end
    def get_nodes__expand_node_groups(opts={})
      cols = opts[:cols]||Node.common_columns()
      node_or_ngs = get_nodes(*cols)
      ServiceNodeGroup.expand_with_node_group_members?(node_or_ngs,opts)
    end

    def get_augmented_components(opts=Opts.new)
      ret = Array.new
      rows = get_objs(:cols => [:instance_nodes_and_cmps_summary_with_namespace])
      if opts[:filter_proc]
        rows.reject!{|r|!opts[:filter_proc].call(r)}
      elsif opts[:filter_component] != ""
        opts[:filter_component].sub!(/::/, "__")
        rows.reject!{|r| r[:nested_component][:display_name] != opts[:filter_component] }
      end

      return ret if rows.empty?

      components = Array.new
      rows.each do |r|
        if cmp = r[:nested_component]
          # add node and namespace hash information to component hash
          components << cmp.merge(r.hash_subset(:node))#.merge!(r.hash_subset(:namespace)))
        end
      end

      if opts.array(:detail_to_include).include?(:component_dependencies)
        Dependency::All.augment_component_instances!(self,components, Opts.new(:ret_statisfied_by => true))
      end
      components
    end

    def get_tasks(opts={})
      rows = get_objs(:cols => [:tasks])
      if opts[:filter_proc]
        rows.reject!{|r|!opts[:filter_proc].call(r)}
      end
      rows.map{|r|r[:task]}
    end

    def clear_tasks(opts={})
      opts_get_tasks = Hash.new
      unless opts[:include_executing_task]
        opts_get_tasks[:filter_proc] = lambda do |r|
          r[:task][:status] != 'executing'
        end
      end
      task_idhs = get_tasks(opts_get_tasks).map{|r|r.id_handle()}
      Model.delete_instances(task_idhs) unless task_idhs.empty?
      task_idhs
    end

    def get_target()
      get_obj_helper(:target,:target)
    end

    def get_target_idh()
      id_handle().get_parent_id_handle_with_auth_info()
    end

    def self.get_sub_assemblies(assembly_idhs)
      ret = Array.new
      return ret if assembly_idhs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name],
        :filter => [:and,[:oneof,:assembly_id,assembly_idhs.map{|idh|idh.get_id()}],[:eq,:type,"composite"]]
      }
      get_objs(assembly_idhs.first.createMH(),sp_hash).map{|a|a.copy_as_assembly_instance()}
    end
    def get_sub_assemblies()
      self.class.get_sub_assemblies([id_handle()])
    end

    # augmented with node, :component  and link def info
    def get_augmented_ports(opts={})
      ndx_ret = Hash.new
      ret = get_objs(:cols => [:augmented_ports]).map do |r|
        link_def = r[:link_def]
        if link_def.nil? or (link_def[:link_type] == r[:port].link_def_name())
          if get_augmented_ports__matches_on_title?(r[:nested_component],r[:port])
            r[:port].merge(r.slice(:node,:nested_component,:link_def))
          end
        end
      end.compact
      if opts[:mark_unconnected]
        get_augmented_ports__mark_unconnected!(ret,opts)
      end
      ret
    end

    # TODO: more efficient if can do the 'title' match on sql side
    def get_augmented_ports__matches_on_title?(component,port)
      ret = true
      if cmp_title = ComponentTitle.title?(component)
        ret = (cmp_title == port.title?())
      end
      ret
    end
    private :get_augmented_ports__matches_on_title?

    # TODO: there is a field on ports :connected, but it is not correctly updated so need to get ports links to find out what is connected
    def get_augmented_ports__mark_unconnected!(aug_ports,opts={})
      port_links = get_port_links()
      connected_ports =  port_links.map{|r|[r[:input_id],r[:output_id]]}.flatten.uniq
      aug_ports.each do |r|
        if r[:direction] == "input"
          r[:unconnected] = !connected_ports.include?(r[:id])
        end
      end
    end
    private :get_augmented_ports__mark_unconnected!

    def op_status()
      assembly_nodes = get_nodes(:admin_op_status)
      self.class.op_status(assembly_nodes)
    end

    def op_status_all_pending?()
      assembly_nodes = get_nodes(:admin_op_status)
      self.class.op_status_all_pending?(assembly_nodes)
    end

    # returns
    #'running' - if at least one node is running
    #'stopped' - if there is atleast one node stopped and no nodes running
    #'pending' - if all nodes are pending or no nodes
    # nil - if cant tell
    def self.op_status(assembly_nodes)
      return 'pending' if assembly_nodes.empty?
      stop_found = false
      assembly_nodes.each do |node|
        case node[:admin_op_status]
          when 'running'
            return 'running'
          when 'stopped'
            stop_found = true
          when 'pending'
            # no op
          else
            return nil
        end
      end
      stop_found ? 'stopped' : 'pending'
    end

    def self.op_status_all_pending?(assembly_nodes)
      assembly_nodes.find do |node|
        status = node[:admin_op_status]
        status.nil? or status != 'pending'
      end.nil?
    end

    def get_info__flat_list(opts={})
      filter = [:eq,:id,id()]
      self.class.get_info__flat_list(model_handle(),{:filter => filter}.merge(opts))
    end

    def remove_empty_nodes(nodes, opts={})
      filter = [:eq,:id,id()]
      self.class.remove_empty_nodes(model_handle(), nodes, {:filter => filter}.merge(opts))
    end

    def self.remove_empty_nodes(assembly_mh, nodes, opts={})
      assembly_empty_nodes = {}
      target_idh = opts[:target_idh]
      target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id()] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:eq, :type, "composite"], target_filter,opts[:filter]].compact
      col,needs_empty_nodes = list_virtual_column?(opts[:detail_level])
      cols = [:id,:ref,:display_name,:group_id,:component_type,:version,:created_at,col].compact
      ret = get(assembly_mh,{:cols => cols}.merge(opts))

      nodes_ids = ret.map{|r|(r[:node]||{})[:id]}.compact
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:version,:instance_nodes_and_assembly_template],
        :filter => filter
      }
      assembly_empty_nodes = get_objs(assembly_mh,sp_hash).reject{|r|nodes_ids.include?((r[:node]||{})[:id])}

      assembly_empty_nodes.each do |en|
        if node = en[:node]
          nodes.delete_if{|n| n[:id] == node[:id]}
        end
      end

      nodes
    end

    # Simple get assembliy instances
    def self.get(assembly_mh, opts={})
      target_idhs = (opts[:target_idh] ? [opts[:target_idh]] : opts[:target_idhs])
      target_filter = (target_idhs ? [:oneof, :datacenter_datacenter_id, target_idhs.map{|idh|idh.get_id()}] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:eq, :type, "composite"], target_filter,opts[:filter]].compact
      sp_hash = {
        :cols => opts[:cols]||[:id,:group_id,:display_name],
        :filter => filter
      }
      get_these_objs(assembly_mh,sp_hash,:keep_ref_cols=>true) #:keep_ref_cols=>true just in case ref col
    end

    def self.get_info__flat_list(assembly_mh, opts={})
      target_idh = opts[:target_idh]
      target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id()] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:eq, :type, "composite"], target_filter,opts[:filter]].compact
      col,needs_empty_nodes = list_virtual_column?(opts[:detail_level])
      cols = [:id,:ref,:display_name,:group_id,:component_type,:version,:created_at,col].compact
      ret = get(assembly_mh,{:cols => cols}.merge(opts))
      return ret unless needs_empty_nodes

      # add in in assembly nodes without components on them
      nodes_ids = ret.map{|r|(r[:node]||{})[:id]}.compact
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:version,:instance_nodes_and_assembly_template],
        :filter => filter
      }
      assembly_empty_nodes = get_objs(assembly_mh,sp_hash).reject{|r|nodes_ids.include?((r[:node]||{})[:id])}
      ret + assembly_empty_nodes
    end

    def self.get_workspace_object(assembly_mh, opts={})
      target_idh = opts[:target_idh]
      target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id()] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:eq, :type, "composite"],[:eq, :ref, '__workspace'], target_filter,opts[:filter]].compact
      col,needs_empty_nodes = list_virtual_column?(opts[:detail_level])
      sp_hash = {
        :cols => [:id, :display_name,:group_id,:component_type,:version,col].compact,
        :filter => filter
      }
      get_these_objs(assembly_mh,sp_hash)
    end


    # returns column plus whether need to pull in empty assembly nodes (assembly nodes w/o any components)
    #[col,empty_assem_nodes]
    def self.list_virtual_column?(detail_level=nil)
      empty_assem_nodes = false
      col =
        if detail_level.nil?
          nil
        elsif detail_level == "nodes"
          empty_assem_nodes = true
          # TODO: use below for component detail and introduce a more succinct one for nodes
          :instance_nodes_and_cmps_summary
        elsif detail_level == "components"
          empty_assem_nodes = true
          :instance_nodes_and_cmps_summary
        else
          raise Error.new("not implemented list_virtual_column at detail level (#{detail_level})")
        end
      [col,empty_assem_nodes]
    end
    private_class_method :list_virtual_column?

    def get_component_modules(opts={})
      AssemblyModule::Component.get_for_assembly(self,opts)
    end
    ### end: standard get methods

    def add_node(node_name,node_binding_rs=nil)
      # check if node has been added already
      if get_node?([:eq,:display_name,node_name])
        raise ErrorUsage.new("Node (#{node_name}) already belongs to #{pp_object_type} (#{get_field?(:display_name)})")
      end

      target = get_target()

      node_template = Node::Template.find_matching_node_template(target,:node_binding_ruleset => node_binding_rs)

      override_attrs = {
        :display_name => node_name,
        :assembly_id => id(),
      }
      clone_opts = node_template.source_clone_info_opts()
      new_obj = target.clone_into(node_template,override_attrs,clone_opts)
      new_obj && new_obj.id_handle()
    end

    def add_component(node_idh,component_template,component_title,namespace=nil)
      # first check that node_idh is directly attached to the assembly instance
      # one reason it may not be is if its a node group member
      sp_hash = {
        :cols => [:id, :display_name,:group_id, :ordered_component_ids],
        :filter => [:and, [:eq, :id, node_idh.get_id()], [:eq, :assembly_id, id()]]
      }
      unless node = Model.get_obj(model_handle(:node),sp_hash)
        if node_group = is_node_group_member?(node_idh)
          raise ErrorUsage.new("Not implemented: adding a component to a node group member; a component can only be added to the node group (#{node_group[:display_name]}) itself") 
        else
          raise ErrorIdInvalid.new(node_idh.get_id(),:node)
        end
      end

      opts = {:skip_if_not_found => true}
      cmp_instance_idh = nil

      Transaction do
        cmp_instance_idh = node.add_component(component_template,component_title,namespace)
        Task::Template::ConfigComponents.update_when_added_component?(self,node,cmp_instance_idh.create_object(),component_title,opts)
      end
      cmp_instance_idh
    end

    #rturns a node group object if node_idh is a node group member of this assembly instance
    def is_node_group_member?(node_idh)
      sp_hash = {
        :cols => [:id, :display_name,:group_id, :node_members],
        :filter => [:eq, :assembly_id, id()]
      }
      node_id = node_idh.get_id()
      Model.get_objs(model_handle(:node),sp_hash).find{|ng|ng[:node_member].id == node_id}
    end
    private :is_node_group_member?

    def add_assembly_template(assembly_template)
      target = get_target()
      assem_id_assign = {:assembly_id => id()}
      # TODO: want to change node names if dups
      override_attrs = {:node => assem_id_assign.merge(:component_ref => assem_id_assign),:port_link => assem_id_assign}
      clone_opts = {:ret_new_obj_with_cols => [:id,:type]}
      new_assembly_part_obj = target.clone_into(assembly_template,override_attrs,clone_opts)
      self.class.delete_instance(new_assembly_part_obj.id_handle())
      id_handle()
    end

    def add_service_add_on(add_on_name, assembly_name=nil)
      update_object!(:display_name)

      unless aug_service_add_on = get_augmented_service_add_on(add_on_name)
        raise ErrorUsage.new("Service add on (#{add_on_name}) is not a possible extension for assembly (#{self[:display_name]})")
      end
      sub_assembly_template = aug_service_add_on[:sub_assembly_template].copy_as_assembly_template()

      override_attrs = {
        :display_name => assembly_name||aug_service_add_on.new_sub_assembly_name(self,sub_assembly_template),
        :assembly_id => id()
      }
      clone_opts = {
        :ret_new_obj_with_cols => [:id,:type],
        :service_add_on_info => {
          :base_assembly => self,
          :service_add_on => aug_service_add_on
        }
      }
      target = get_target()
      new_sub_assembly = target.clone_into(sub_assembly_template,override_attrs,clone_opts)
      new_sub_assembly && new_sub_assembly.id_handle()
    end

    def create_or_update_template(service_module,template_name)
      service_module_name = service_module.get_field?(:display_name)
      project = service_module.get_project()
      node_idhs = get_nodes().map{|r|r.id_handle()}
      if node_idhs.empty?
        raise ErrorUsage.new("Cannot find any nodes associated with assembly (#{get_field?(:display_name)})")
      end
      Assembly::Template.create_or_update_from_instance(project,node_idhs,template_name,service_module_name)
    end

    def set_attribute(attribute,value,opts={})
      set_attributes([{:pattern => attribute,:value => value}],opts)
    end

    def set_attributes(av_pairs,opts={})
      attr_patterns = nil
      Transaction do
        attr_patterns = super
        if opts[:update_meta]
          created_cmp_level_attrs = attr_patterns.select{|r|r.type == :component_level and r.created?()}
          unless created_cmp_level_attrs.empty?
            AssemblyModule::Component::Attribute.update(self,created_cmp_level_attrs)
          end
        end
      end
      attr_patterns
    end

    def get_attributes_print_form(opts={})
      if filter = opts[:filter]
        case filter
          when :required_unset_attributes
            opts.merge!(:filter_proc => FilterProc)
          else
            raise Error.new("not treating filter (#{filter}) in Assembly::Instance#get_attributes_print_form")
        end
      end
      get_attributes_print_form_aux(opts)
    end
    FilterProc = lambda do |r|
      attr =
        if r.kind_of?(Attribute) then r
        elsif r[:attribute] then r[:attribute]
        else raise Error.new("Unexpected form for filtered element (#{r.inspect})")
        end
      attr.required_unset_attribute?()
    end

    def get_attributes_all_levels()
      assembly_attrs = get_assembly_level_attributes()
      component_attrs = get_augmented_nested_component_attributes()
      node_attrs = get_augmented_node_attributes()
      assembly_attrs + component_attrs + node_attrs
    end

    AttributesAllLevels = Struct.new(:assembly_attrs,:component_attrs,:node_attrs)
    def get_attributes_all_levels_struct(filter_proc=nil)
      assembly_attrs = get_assembly_level_attributes(filter_proc)
      component_atttrs = get_augmented_nested_component_attributes(filter_proc).reject do |attr|
        (not attr[:nested_component].get_field?(:only_one_per_node)) and attr.is_title_attribute?()
      end
      node_attrs = get_augmented_node_attributes(filter_proc)
      AttributesAllLevels.new(assembly_attrs,component_atttrs,node_attrs)
    end

    def get_attributes_print_form_aux(opts=Opts.new)
      filter_proc = opts[:filter_proc]
      all_attrs = get_attributes_all_levels_struct(filter_proc)
      filter_proc = opts[:filter_proc]
      assembly_attrs = all_attrs.assembly_attrs.map do |attr|
        attr.print_form(opts.merge(:level => :assembly))
      end

      opts_attr = opts.merge(:level => :component,:assembly => self)
      component_attrs = Attribute.print_form(all_attrs.component_attrs,opts_attr)

      node_attrs = all_attrs.node_attrs.map do |aug_attr|
        aug_attr.print_form(opts.merge(:level => :node))
      end
      (assembly_attrs + node_attrs + component_attrs).sort{|a,b|a[:display_name] <=> b[:display_name]}
    end
    private :get_attributes_print_form_aux


    def self.check_valid_id(model_handle,id)
      filter =
        [:and,
         [:eq, :id, id],
         [:eq, :type, "composite"],
         [:neq, :datacenter_datacenter_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end

    def self.name_to_id(model_handle,name)
      parts = name.split("/")
      augmented_sp_hash =
        if parts.size == 1
          {:cols => [:id],
           :filter => [:and,
                      [:eq, :display_name, parts[0]],
                      [:eq, :type, "composite"],
                      [:neq, :datacenter_datacenter_id, nil]]
          }
        elsif parts.size == 2
          {:cols => [:id,:component_type,:target],
           :filter => [:and,
                      [:eq, :display_name, parts[1]],
                      [:eq, :type, "composite"]],
           :post_filter => lambda{|r|r[:target][:display_name] ==  parts[0]}
          }
        else
          raise ErrorNameInvalid.new(name,pp_object_type())
        end
      name_to_id_helper(model_handle,name,augmented_sp_hash)
    end

    # TODO: probably move to Assembly
    def model_handle(mn=nil)
      super(mn||:component)
    end

   private
    def get_associated_template?(library_idh=nil)
      update_object!(:ancestor_id,:component_type,:version,:ui)
      if self[:ancestor_id]
        return id_handle(:id => self[:ancestor_id]).create_object().update_object!(:library_library_id,:ui)
      end
      sp_hash = {
        :cols => [:id,:library_library_id,:ui],
        :filter => [:and, [:eq, :component_type, self[:component_type]],
                    [:neq, :library_library_id, library_idh && library_idh.get_id()],
                    [:eq, :version, self[:version]]]
      }
      rows = Model.get_objs(model_handle(),sp_hash)
      case rows.size
       when 0 then nil
       when 1 then rows.first
       else raise Error.new("Unexpected result: cannot find unique matching assembly template")
      end
    end

  end
end
# TODO: hack to get around error in lib/model.rb:31:in `const_get
AssemblyInstance = Assembly::Instance
end

