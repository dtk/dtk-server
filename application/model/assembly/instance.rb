module DTK; class  Assembly
  class Instance < self
    r8_nested_require('instance','action')
    r8_nested_require('instance','violation')
    r8_nested_require('instance','service_link')
    r8_nested_require('instance','update')
    include ActionMixin
    include ViolationMixin
    include ServiceLinkMixin

    def self.get_objs(mh,sp_hash,opts={})
      if mh[:model_name] == :assembly_instance
        super(mh.createMH(:component),sp_hash,opts).map{|cmp|create_from_component(cmp)}
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
      format = opts[:format]||:hash
      if format == :hash
        opts_task_gen = {:task_action => task_action,:dont_persist_generated_template => true}
        ret = Task::Template::ConfigComponents.get_or_generate_template_content([:assembly,:node_centric],self,opts_task_gen)
        ret && ret.serialization_form()
      else
        raise ErrorUsage.new("Getting assembly task template with format (#{format}) not support")
      end
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
      #TODO: once field assembly_id is always populated on attribute.link, can do simpler query
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

    def get_nodes(*alt_cols)
      self.class.get_nodes([id_handle],*alt_cols)
    end
    def self.get_nodes(assembly_idhs,*alt_cols)
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

      cols = ([:id,:display_name,:group_id] + alt_cols).uniq
      sp_hash = {
        :cols => cols,
        :filter => [:or,[:oneof, :id, ndx_nodes.keys],
                    [:oneof,:assembly_id,assembly_idhs.map{|idh|idh.get_id()}]] #to catch nodes without any components
      }
      node_mh = assembly_idhs.first.createMH(:node)
      get_objs(node_mh,sp_hash)
    end

    def get_augmented_components(opts=Opts.new)
      ret = Array.new
      rows = get_objs(:cols => [:instance_nodes_and_cmps_summary])
      if opts[:filter_proc]
        rows.reject!{|r|!opts[:filter_proc].call(r)}
      end
      return ret if rows.empty?

      components = Array.new
      rows.each do |r|
        if cmp = r[:nested_component]
          components << cmp.merge(r.hash_subset(:node))
        end
      end

      if opts.array(:detail_to_include).include?(:component_dependencies)
        Dependency::All.augment_component_instances!(self,components, Opts.new(:ret_statisfied_by => true))
      end
      components
    end

    def get_tasks(opts=Opts.new)
      ret = get_objs(:cols => [:tasks])
      if opts[:filter_proc]
        ret.reject!{|r|!opts[:filter_proc].call(r)}
      end
      ret
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

    #augmented with node, :component  and link def info
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

    #TODO: more efficient if can do the 'title' match on sql side
    def get_augmented_ports__matches_on_title?(component,port)
      ret = true
      if cmp_title = ComponentTitle.title?(component)
        ret = (cmp_title == port.title?())
      end
      ret
    end
    private :get_augmented_ports__matches_on_title?

    #TODO: there is a field on ports :connected, but it is not correctly updated so need to get ports links to find out what is connected
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

    def self.op_status(assembly_nodes)
      return "pending" if assembly_nodes.empty?
      pending_status = nil
      stop_status    = nil
      assembly_nodes.each do |node|
        if (status = node[:admin_op_status]).eql? "stopped"
          stop_status = "stopped"; break
        elsif status.eql? "pending"
          pending_status = "pending"
        end
      end
      stop_status||pending_status||"running"    
    end

    def get_info__flat_list(opts={})
      filter = [:eq,:id,id()]
      self.class.get_info__flat_list(model_handle(),{:filter => filter}.merge(opts))
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
      get_objs(assembly_mh,sp_hash)
    end

    def self.get_info__flat_list(assembly_mh, opts={})
      target_idh = opts[:target_idh]
      target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id()] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:eq, :type, "composite"], target_filter,opts[:filter]].compact
      col,needs_empty_nodes = list_virtual_column?(opts[:detail_level])
      sp_hash = {
        :cols => [:id, :display_name,:group_id,:component_type,:version,col].compact,
        :filter => filter
      }
      ret = get_objs(assembly_mh,sp_hash)
      return ret unless needs_empty_nodes

      #add in in assembly nodes without components on them
      nodes_ids = ret.map{|r|(r[:node]||{})[:id]}.compact
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:version,:instance_nodes_and_assembly_template],
        :filter => filter
      }
      assembly_empty_nodes = get_objs(assembly_mh,sp_hash).reject{|r|nodes_ids.include?((r[:node]||{})[:id])}
      ret + assembly_empty_nodes
    end


    def self.list_with_workspace(assembly_mh,opts={})
      target_idh = opts[:target_idh]
      target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id()] : [:neq, :datacenter_datacenter_id, nil])
      filter = [:and, [:eq, :type, "composite"], target_filter,opts[:filter]].compact

      sp_hash = {
        :cols => [:id, :display_name].compact,
        :filter => filter
      }
      get_objs(assembly_mh,sp_hash)
    end
    
    class << self
     private
      #returns column plus whether need to pul in empty assembly nodes (assembly nodes w/o any components)
      def list_virtual_column?(detail_level=nil)
        empty_assem_nodes = false
        col = 
        if detail_level.nil?
          nil
        elsif detail_level == "nodes"
          empty_assem_nodes = true
          #TODO: use below for component detail and introduce a more succinct one for nodes
          :instance_nodes_and_cmps_summary
        elsif detail_level == "components"
          empty_assem_nodes = true
          :instance_nodes_and_cmps_summary
        else
          raise Error.new("not implemented list_virtual_column at detail level (#{detail_level})")
        end
        [col,empty_assem_nodes]

      end
    end

    ### end: standard get methods
    
    def self.list(assembly_mh,opts={})
      assembly_rows = get_info__flat_list(assembly_mh,opts)

      if opts[:detail_level].nil?
        list_aux__no_details(assembly_rows)
      else
        get_attrs = [opts[:detail_level]].flatten.include?("attributes")
        attr_rows = get_attrs ? get_default_component_attributes(assembly_mh,assembly_rows) : []
        add_execution_status!(assembly_rows,assembly_mh)
        
        list_aux(assembly_rows,attr_rows,opts)
      end
    end

    def list_smoketests()
      Log.error("TODO: needs to be tested")
      nodes_and_cmps = get_info__flat_list(:detail_level => "components")
      nodes_and_cmps.map{|r|r[:nested_component]}.select{|cmp|cmp[:basic_type] == "smoketest"}.map{|cmp|Aux::hash_subset(cmp,[:id,:display_name,:description])}
    end

    def display_name_print_form(opts={})
      self.class.pretty_print_name(self,opts)
    end

    class << self
      def get_assemblies_with_nodes(mh,opts={})
        Log.error("TODO: remove or fix up top reflect nodes can be asseociated with multiple assemblies")
        target_idh = opts[:target_idh]
        target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id()] : [:neq, :datacenter_datacenter_id, nil])
        sp_hash = {
          :cols => [:id, :display_name,:nested_nodes_summary],
          :filter => [:and, [:eq, :type, "composite"], target_filter]
        }
        assembly_rows = get_objs(mh.createMH(:component),sp_hash)

        ndx_ret = Hash.new
        assembly_rows.each do |r|
          node = r.delete(:node)
          next if node.nil?
          ((ndx_ret[r[:id]] ||= r)[:nodes] ||= Array.new) << node
        end
        ndx_ret.each_value{|r|r[:is_staged] = !r[:nodes].find{|n|n[:type] != "staged"}}
        ndx_ret.values
      end

      def pretty_print_name(assembly,opts={})
        assembly.get_field?(:display_name)
      end

     private
      def list_aux__no_details(assembly_rows)
        assembly_rows.map do |r|
          #TODO: hack to create a Assembly object (as opposed to row which is component); should be replaced by having 
          #get_objs do this (using possibly option flag for subtype processing)
          r.id_handle.create_object().merge(:display_name => pretty_print_name(r))
        end
      end

      def add_execution_status!(assembly_rows,assembly_mh)
        sp_hash = {
          :cols => [:id,:started_at,:assembly_id,:status],
          :filter => [:oneof,:assembly_id,assembly_rows.map{|r|r[:id]}]
        }
        ndx_task_rows = Hash.new
        get_objs(assembly_mh.createMH(:task),sp_hash).each do |task|
          next unless task[:started_at]
          assembly_id = task[:assembly_id]
          if pntr = ndx_task_rows[assembly_id]
            if task[:started_at] > pntr[:started_at] 
              ndx_task_rows[assembly_id] =  task.slice(:status,:started_at)
            end
          else
            ndx_task_rows[assembly_id] = task.slice(:status,:started_at)
          end
        end
        #TODO: make sure this is right
        assembly_rows.each do |r|
          if node = r[:node]
            unless execution_status = ndx_task_rows[r[:id]] && ndx_task_rows[r[:id]][:status]
              execution_status =
                case node[:admin_op_status]
                  when "stopped" then "stopped"
                  when "running" then "running"
                  when "pending" then "staged"
                end
            end
            r[:execution_status] = execution_status
          end
        end
        assembly_rows
      end
    end

    def info_about(about,opts=Opts.new)
      case about 
       when :attributes
        get_attributes_print_form_aux(opts).map do |a|
          Aux::hash_subset(a,[:id,:display_name,:value,:linked_to_display_form])
        end.sort{|a,b| a[:display_name] <=> b[:display_name] }

       when :components
        list_components(opts)

       when :nodes
        get_nodes(:id,:display_name,:admin_op_status,:os_type,:external_ref,:type).sort{|a,b| a[:display_name] <=> b[:display_name] }

       when :tasks
        get_tasks(opts).map do |r|
          r[:task]
        end.compact.sort{|a,b|(b[:started_at]||b[:created_at]) <=> (a[:started_at]||a[:created_at])} #TODO: might encapsualet in Task; ||foo[:created_at] used in case foo[:started_at] is null

       else
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
    end

    def list_components(opts=Opts.new)
      aug_cmps = get_augmented_components(opts)
      ret = aug_cmps.map do |r|
        display_name = "#{r[:node][:display_name]}/#{Component::Instance.print_form(r)}"
        version = Component::Instance.version_print_form(r)
        #TODO: dont think this is needed anymore
        # Remove version from display name
        #          display_name.sub!(/\((\d{1,2}).(\d{1,2}).(\d{1,2})\)/, '')
        r.hash_subset(:id).merge({:display_name => display_name, :version => version})
      end
      
      main_table_sort = proc{|a,b|a[:display_name] <=> b[:display_name]}
      if opts.array(:detail_to_include).include?(:component_dependencies)
        opts.set_return_value!(:datatype,:component_with_dependencies)
        ndx_component_print_form = ret_ndx_component_print_form(aug_cmps,ret)
        join_columns = OutputTable::JoinColumns.new(aug_cmps) do |aug_cmp|
          if deps = aug_cmp[:dependencies]
            deps.map do |dep|
              el = {:depends_on => dep.depends_on_print_form?()}
              sb_cmp_ids = dep.satisfied_by_component_ids
              unless sb_cmp_ids.empty?
                satisfied_by = sb_cmp_ids.map{|cmp_id|ndx_component_print_form[cmp_id]}.join(', ')
                el.merge!(:satisfied_by => satisfied_by)
              end
              el
            end.compact
          end
        end
        OutputTable.join(ret,join_columns,&main_table_sort)
      else
        opts.set_return_value!(:datatype,:component)
        ret.sort(&main_table_sort)
      end
    end



    def get_augmented_component_modules()
      ndx_ret = Hash.new
      get_objs(:cols=> [:instance_component_module_branches]).each do |r|
        component_module = r[:component_module]
        pntr = ndx_ret[component_module[:id]] ||= component_module.merge(:module_branches=>Array.new)
        pntr[:module_branches] << r[:module_branch]
      end
      ndx_ret.values
    end
    def get_component_modules()
      ndx_ret = Hash.new
      get_objs(:cols=> [:instance_component_module_branches]).each do |r|
        component_module = r[:component_module]
        ndx_ret[component_module[:id]] ||= component_module
      end
      ndx_ret.values
    end
    #TODO: see if below can use above
    def get_components_module(component_id)
      component, version = nil, nil
      aug_cmps = get_augmented_components()

      ret = aug_cmps.map do |r|
        component = r if r[:id]==component_id.to_i
      end
      
      if branch_id = component[:module_branch_id]
        sp_hash = {
          :cols => [:id,:display_name,:version],
          :filter => [:eq, :id, branch_id]
        }
        module_branch = Model.get_obj(model_handle(:module_branch),sp_hash)
        component = module_branch.get_module()
        version   = module_branch[:version]
      end

      {:component => component, :version => (version=="master" ? nil : version)}
    end

    def ret_ndx_component_print_form(aug_cmps,cmps_with_print_form)
      #has lookup taht includes each satisfied_by_component
      ret = cmps_with_print_form.inject(Hash.new){|h,cmp|h.merge(cmp[:id] => cmp[:display_name])}

      #see if theer is any components that are nreferenced but not in ret
      needed_cmp_ids = Array.new
      aug_cmps.each do |aug_cmp|
        if deps = aug_cmp[:dependencies]
          deps.map do |dep|
            dep.satisfied_by_component_ids.each do |cmp_id|
              needed_cmp_ids << cmp_id if ret[cmp_id].nil?
            end
          end
        end
      end
      return ret if needed_cmp_ids.empty?

      filter_array = needed_cmp_ids.map{|cmp_id|[:eq,:id,cmp_id]}
      filter = (filter_array.size == 1 ? filter_array.first : [:or] + filter_array)
      additional_cmps = list_components(Opts.new(:filter => filter))
      additional_cmps.inject(ret){|h,cmp|h.merge(cmp[:id] => cmp[:display_name])}
    end
    private :ret_ndx_component_print_form

    def self.delete(assembly_idhs,opts={})
      if assembly_idhs.kind_of?(Array)
        return if assembly_idhs.empty?
      else
        assembly_idhs = [assembly_idhs]
      end
      #cannot delete workspaces
      if workspace = assembly_idhs.find{|idh|Workspace.is_workspace?(idh.create_object())}
        raise ErrorUsage.new("Cannot delete a workspace")
      end
      delete_contents(assembly_idhs,opts)
      delete_instances(assembly_idhs)
    end

    def self.delete_contents(assembly_idhs,opts={})
      return if assembly_idhs.empty?
      delete(get_sub_assemblies(assembly_idhs).map{|r|r.id_handle()})
      assembly_ids = assembly_idhs.map{|idh|idh.get_id()}
      idh = assembly_idhs.first
      delete_assembly_modules?(assembly_idhs)
      #delete_assembly_modules? needs to be done before delete_assembly_nodes
      delete_assembly_nodes(idh.createMH(:node),assembly_ids,opts)
      delete_task_templates(idh.createMH(:task_template),assembly_ids)
    end

    class << self
     private
      def delete_task_templates(task_template_mh,assembly_ids)
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:oneof,:component_component_id,assembly_ids] 
        }
        delete_instances(get_objs(task_template_mh,sp_hash).map{|tt|tt.id_handle()})
      end

      def delete_assembly_modules?(assembly_idhs)
        assembly_idhs.each do |assembly_idh|
          assembly = create_from_id_handle(assembly_idh)
          AssemblyModule.delete_modules?(assembly)
        end
      end

      def delete_assembly_nodes(node_mh,assembly_ids,opts={})
        #This only deletes the nodes that the assembly 'owns'; with sub-assemblies, the assembly base will own the node
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:oneof,:assembly_id,assembly_ids]
        }
        get_objs(node_mh,sp_hash).map{|node|delete_node_aux(node,opts)}
      end
    end
    def self.delete_node_aux(node,opts={})
      ret = nil
      Transaction do 
        ret = 
          if opts[:destroy_nodes]
            node.destroy_and_delete(opts)
          else
            node.delete_object(opts)
          end
      end
      ret
    end

    def delete_node(node_idh,opts={})
      node =  node_idh.create_object()
      #TODO: check if cleaning up dangling links when assembly node deleted
      self.class.delete_node_aux(node,opts.merge(:update_task_template=>true,:assembly=>self))
    end

    def add_node(node_name,node_binding_rs=nil)
      #check if node has been added already
      if get_node?([:eq,:display_name,node_name])
        raise ErrorUsage.new("Node (#{node_name}) already belongs to assembly (#{get_field?(:display_name)})")
      end

      target = get_target()

      node_template = 
        if node_binding_rs
          node_binding_rs.find_matching_node_template(target)
        else
          Node::Template.null_node_template(model_handle(:node))
        end
      
      override_attrs = {
        :display_name => node_name,
        :assembly_id => id(),
      }
      clone_opts = node_template.source_clone_info_opts()
      new_obj = target.clone_into(node_template,override_attrs,clone_opts)
      new_obj && new_obj.id_handle()
    end

    def add_component(node_idh,component_template,component_title)
      #first check that node_idh belongs to this instance
      sp_hash = {
        :cols => [:id, :display_name,:group_id, :ordered_component_ids],
        :filter => [:and, [:eq, :id, node_idh.get_id()], [:eq, :assembly_id, id()]]
      }
      unless node = Model.get_obj(model_handle(:node),sp_hash)
        raise ErrorIdInvalid.new(node_idh.get_id(),:node)
      end

      cmp_instance_idh = nil
      Transaction do
        cmp_instance_idh = node.add_component(component_template,component_title)
        Task::Template::ConfigComponents.update_when_added_component?(self,node,cmp_instance_idh.create_object(),component_title)
      end
      cmp_instance_idh
    end

    def delete_component(component_idh, node_id=nil)
      component_filter = [:and, [:eq, :id, component_idh.get_id()], [:eq, :assembly_id, id()]]
      node = nil
      # first check that node belongs to this assebmly
      unless !node_id.nil? && node_id.empty?
        sp_hash = {
          :cols => [:id, :display_name,:group_id],
          :filter => [:and, [:eq, :id, node_id], [:eq, :assembly_id, id()]]
        }

        unless node = Model.get_obj(model_handle(:node),sp_hash)
          raise ErrorIdInvalid.new(node_id,:node)
        end
        component_filter << [:eq, :node_node_id, node_id]
      end
 
      # also check that component_idh belongs to this instance and to this node
      sp_hash = {
        #:only_one_per_node,:ref are put in for info needed when getting title
        :cols => [:id, :display_name, :node_node_id,:only_one_per_node,:ref],
        :filter => component_filter
      }
      component = Component::Instance.get_obj(model_handle(:component),sp_hash)
      unless component
        raise ErrorIdInvalid.new(component_idh.get_id(),:component)
      end
      node ||= component_idh.createIDH(:model_name => :node,:id => component[:node_node_id]).create_object()
      ret = nil
      Transaction do
        Task::Template::ConfigComponents.update_when_deleted_component?(self,node,component)
        ret = Model.delete_instance(component_idh)
      end
      ret
    end
=begin
#TODO: Deprecating DEPENDENCY-ORDER-INDEX
...      
      # Amar: Retrieving node object to update components order
      sp_hash = {
        :cols => [:id, :ordered_component_ids],
        :filter => [:and, [:eq, :id, component[:node_node_id]], [:eq, :assembly_id, id()]]
      }
      node = Model.get_obj(model_handle(:node),sp_hash)
      order = node.get_ordered_component_ids()
      order.delete(component_idh.get_id())
      node.update_ordered_component_ids(order)
    end
=end

    def add_assembly_template(assembly_template)
      target = get_target()
      assem_id_assign = {:assembly_id => id()}
      #TODO: want to change node names if dups
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
      #TODO: more efficient is tahey do not need to be augmenetd
      component_attrs = get_augmented_nested_component_attributes()
      node_attrs = get_augmented_node_attributes()
      assembly_attrs + component_attrs + node_attrs
    end

    def get_attributes_print_form_aux(opts={})
      filter_proc = opts[:filter_proc]
      assembly_attrs = get_assembly_level_attributes(filter_proc).map do |attr|
        attr.print_form(opts.merge(:level => :assembly))
      end

      raw_cmp_attrs = get_augmented_nested_component_attributes(filter_proc).reject do |attr|
        (not attr[:nested_component].get_field?(:only_one_per_node)) and attr.is_title_attribute?()
      end
      component_attrs = Attribute.print_form(raw_cmp_attrs,opts.merge(:level => :component,:assembly => self))

      node_attrs = get_augmented_node_attributes(filter_proc).map do |aug_attr|
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

    #TODO: probably move to Assembly
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
#TODO: hack to get around error in /home/dtk/server/system/model.r8.rb:31:in `const_get
AssemblyInstance = Assembly::Instance
end

