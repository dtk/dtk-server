module DTK; class  Assembly
  class Instance < self
    r8_nested_require('instance','service_link_mixin')
    r8_nested_require('instance','service_link')
    r8_nested_require('instance','action')
    r8_nested_require('instance','violation')
    r8_nested_require('instance','update')
    r8_nested_require('instance','list')
    r8_nested_require('instance','get')
    r8_nested_require('instance','delete')
    r8_nested_require('instance','service_setting')
    include ServiceLinkMixin
    include ViolationMixin
    include ListMixin
    extend ListClassMixin
    include DeleteMixin
    extend DeleteClassMixin
    include GetMixin
    extend GetClassMixin

    def self.create_from_id_handle(idh)
      idh.create_object(:model_name => :assembly_instance)
    end

    def rename(assembly_mh, name, new_name)
      assembly_list = Assembly::Instance.list(assembly_mh)
      raise ErrorUsage.new("You are not allowed to use keyword '#{new_name}' as #{pp_object_type()} name") if new_name.to_s.eql?("workspace")

      assembly_list.each do |assembly|
        raise ErrorUsage.new("#{pp_object_type().cap} with name '#{new_name}' exists already") if assembly[:display_name].to_s.eql?(new_name)
      end

      update(:display_name => new_name)
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
        # super does the processing that sets the actual attributes then if opts[:update_meta] set
        # then if opts[:update_meta] set meta info can be changed on the assembly module
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

  end
end
# TODO: hack to get around error in lib/model.rb:31:in `const_get
AssemblyInstance = Assembly::Instance
end

