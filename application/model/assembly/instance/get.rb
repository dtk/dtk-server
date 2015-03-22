module DTK; class Assembly; class Instance
  module Get
    r8_nested_require('get','attribute')
  end
  module GetMixin
    include Get::AttributeMixin

    def get_objs(sp_hash,opts={})
      super(sp_hash,opts.merge(:model_handle => model_handle().createMH(:assembly_instance)))
    end

    # get associated task template
    def get_parent()
      Template.create_from_component(get_obj_helper(:instance_parent,:assembly_template))
    end

    def get_target()
      get_obj_helper(:target,:target)
    end

    def get_target_idh()
      id_handle().get_parent_id_handle_with_auth_info()
    end


    #### get methods around attribute mappings
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
    #### end: get methods around attribute mappings

    #### get methods around components
    def get_component_info_for_action_list(opts={})
      get_field?(:display_name)
      assembly_source = {:type => "assembly", :object => hash_subset(:id,:display_name)}
      rows = get_objs_helper(:instance_component_list,:nested_component,opts.merge(:augmented => true))
      Component::Instance.add_title_fields?(rows)
      Component::Instance.add_action_defs!(rows,:cols=>[:method_name])
      ret = opts[:add_on_to]||opts[:seed]||Array.new
      rows.each{|r|ret << r.merge(:source => assembly_source)}
      ret
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

    def get_component_instances(opts={})
      sp_hash = {
        :cols => opts[:cols] || [:id,:group_id,:display_name,:component_type],
        :filter => [:eq,:assembly_id,id()]
      }
      Component::Instance.get_objs(model_handle(:component_instance),sp_hash)
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
    #### end: get methods around components

    #### get methods around component modules
    def get_component_modules(opts={})
      AssemblyModule::Component.get_for_assembly(self,opts)
    end
    #### end: get methods around component modules

    #### get methods around nodes
    def get_leaf_nodes(opts={})
      get_nodes__expand_node_groups(opts.merge(:remove_node_groups=>true))
    end

    def get_nodes__expand_node_groups(opts={})
      cols = opts[:cols]||Node.common_columns()
      node_or_ngs = get_nodes(*cols)
      ServiceNodeGroup.expand_with_node_group_members?(node_or_ngs,opts)
    end

    def get_node_groups(opts={})
      cols = opts[:cols]||Node.common_columns()
      node_or_ngs = get_nodes(*cols)
      ServiceNodeGroup.get_node_groups?(node_or_ngs)
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
    def get_nodes(*alt_cols)
      self.class.get_nodes([id_handle],*alt_cols)
    end
    #### end: get methods around nodes

    #### end: get methods around ports
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
    #### end: get methods around ports

    #### get methods around service add ons
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

    #### end: get methods around service add ons
    def get_tasks(opts={})
      rows = get_objs(:cols => [:tasks])
      if opts[:filter_proc]
        rows.reject!{|r|!opts[:filter_proc].call(r)}
      end
      rows.map{|r|r[:task]}
    end

    #### get methods around task templates
    def get_task_templates(opts={})
      sp_hash = {
        :cols => Task::Template.common_columns(),
        :filter => [:eq,:component_component_id,id()]
      }
      Model.get_objs(model_handle(:task_template),sp_hash)
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

    def get_task_template_serialized_content(task_action=nil,opts={})
      action_types = [:assembly] # TODO: action_types can be set to [:assembly,:node_centric] if treating inventory node groups
      opts_task_gen = {:serialized_form => true}.merge(opts)
      opts_task_gen.merge!(:task_action => task_action) if task_action

      ret = Task::Template::ConfigComponents.get_or_generate_template_content(action_types,self,opts_task_gen)
      ret && ret.serialization_form(opts[:serialization_form]||{})
    end

    def get_task_templates_with_serialized_content()
      ret = Array.new

      opts = {
        :component_type_filter => :service, 
        :serialization_form    => {:filter => {:source => :assembly}, :allow_empty_task=>true}
      }

      # TODO: only returning now the task templates for the default (assembly create action)
      # this is done by setting task action as nil
      task_action =  nil
      if serialized_content = get_task_template_serialized_content(task_action,opts)
        action_task_template = get_task_template(task_action,:cols => [:id,:group_id,:task_action])
        action_task_template ||= Assembly::Instance.create_stub(model_handle(:task_template))
        ret << action_task_template.merge(:content => serialized_content)
      end
      ret
    end

    def get_parents_task_template(task_action=nil)
      task_action ||= Task::Template.default_task_action()
      get_objs_helper(:parents_task_templates,:task_template).select{|r|r[:task_action]==task_action}.first
    end
    #### end: get methods around task templates

    def get_sub_assemblies()
      self.class.get_sub_assemblies([id_handle()])
    end
  end

  module GetClassMixin
    def get_objs(mh,sp_hash,opts={})
      if mh[:model_name] == :assembly_instance
        get_these_objs(mh,sp_hash,opts)
      else
        super
      end
    end

    def get(assembly_mh, opts={})
      target_idhs = (opts[:target_idh] ? [opts[:target_idh]] : opts[:target_idhs])
      target_filter = (target_idhs ? [:oneof, :datacenter_datacenter_id, target_idhs.map{|idh|idh.get_id()}] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:eq, :type, "composite"], target_filter,opts[:filter]].compact
      sp_hash = {
        :cols => opts[:cols]||[:id,:group_id,:display_name],
        :filter => filter
      }
      get_these_objs(assembly_mh,sp_hash,:keep_ref_cols=>true) #:keep_ref_cols=>true just in case ref col
    end

    def get_info__flat_list(assembly_mh, opts={})
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

    def get_workspace_object(assembly_mh, opts={})
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

    #### get methods around nodes
    def get_nodes(assembly_idhs,*alt_cols)
      ret = Array.new
      return ret if assembly_idhs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:node_node_id],
        :filter => [:oneof, :assembly_id, assembly_idhs.map{|idh|idh.get_id()}]
      }
      ndx_nodes = Hash.new
      component_mh = assembly_idhs.first.createMH(:component)
      get_objs(component_mh,sp_hash).each do |cmp|
        ndx_nodes[cmp[:node_node_id]] ||= true
      end

      cols = ([:id,:display_name,:group_id,:type] + alt_cols).uniq
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

    # TODO: rename to reflect that not including node group members, just node groups themselves and top level nodes
    # This is equivalent to saying that this does not return target_refs
    def get_nodes_simple(assembly_idhs,opts={})
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
    #### end: get methods around nodes

    def get_sub_assemblies(assembly_idhs)
      ret = Array.new
      return ret if assembly_idhs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name],
        :filter => [:and,[:oneof,:assembly_id,assembly_idhs.map{|idh|idh.get_id()}],[:eq,:type,"composite"]]
      }
      get_objs(assembly_idhs.first.createMH(),sp_hash).map{|a|a.copy_as_assembly_instance()}
    end

   private
    def filter_out_target_refs()
      @filter_out_target_ref ||= [:and] + Node::TargetRef.types.map{|t|[:neq, :type, t]}
    end
  end
end; end; end

