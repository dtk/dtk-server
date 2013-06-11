module DTK; class  Assembly
  class Instance < self
    r8_nested_require('instance','action')
    r8_nested_require('instance','violation')
    r8_nested_require('instance','service_link')
    include ActionMixin
    include ViolationMixin
    include ServiceLinkMixin

    ### standard get methods
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
      return ret if port_links.empty?
      AttributeLink.get_augmented(model_handle(:attribute_link),[:oneof,:port_link_id,port_links.map{|r|r.id()}])
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

      components = rows.map do |r|
        r[:nested_component].merge(r.hash_subset(:node))
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

    def get_info__flat_list(opts={})
      filter = [:eq,:id,id()]
      self.class.get_info__flat_list(model_handle(),{:filter => filter}.merge(opts))
    end

    def self.get_info__flat_list(assembly_mh,opts={})
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
      nodes_ids = ret.map{|r|r[:node][:id]}
      sp_hash = {
        :cols => [:id, :display_name,:component_type,:version,:instance_nodes_and_assembly_template],
        :filter => filter
      }
      assembly_empty_nodes = get_objs(assembly_mh,sp_hash).reject{|r|nodes_ids.include?(r[:node][:id])}
      ret + assembly_empty_nodes
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

     private
      def list_aux__no_details(assembly_rows)
        assembly_rows.map do |r|
          #TODO: hack to create a Assembly object (as opposed to row which is component); should be replaced by having 
          #get_objs do this (using possibly option flag for subtype processing)
          r.id_handle.create_object().merge(:display_name => pretty_print_name(r))
        end
      end

      def pretty_print_name(assembly,opts={})
        assembly[:display_name]
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
          unless execution_status = ndx_task_rows[r[:id]] && ndx_task_rows[r[:id]][:status]
            execution_status =
              case r[:node][:admin_op_status]
                when "stopped" then "stopped"
                when "running" then "running"
                when "pending" then "staged"
              end
          end
          r[:execution_status] = execution_status
        end
        assembly_rows
      end
    end

    def info_about(about,opts=Opts.new)
      case about 
       when :attributes
        get_attributes_print_form_aux(opts).map do |a|
          Aux::hash_subset(a,[:id,:display_name,:value,:linked_to])
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
      raw_rows = get_augmented_components(opts)
      ret = raw_rows.map do |r|
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
        join_columns = OutputTable::JoinColumns.new(raw_rows) do |raw_row|
          if component_deps = raw_row[:dependencies]
            component_deps.map{|dep|{:depends_on => dep.scalar_print_form?()}}.compact
          end
        end
        OutputTable.join(ret,join_columns,&main_table_sort)
      else
        opts.set_return_value!(:datatype,:component)
        ret.sort(&main_table_sort)
      end
    end

    def self.delete(assembly_idhs,opts={})
      if assembly_idhs.kind_of?(Array)
        return if assembly_idhs.empty?
      else
        assembly_idhs = [assembly_idhs]
      end
      delete(get_sub_assemblies(assembly_idhs).id_handles())
      delete_assembly_nodes(assembly_idhs,opts)
      delete_instances(assembly_idhs)
    end

    class << self
     private
      def delete_assembly_nodes(assembly_idhs,opts={})
        return if assembly_idhs.empty?
        #This only deletes the nodes that the assembly 'owns'; with sub-assemblies, the assembly base will own the node
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:oneof, :assembly_id, assembly_idhs.map{|idh|idh.get_id()}]
        }
        node_mh = assembly_idhs.first.createMH(:node)
        assembly_nodes = get_objs(node_mh,sp_hash)
        if opts[:destroy_nodes]
          assembly_nodes.map{|r|r.destroy_and_delete()}
        else
          assembly_nodes.map{|r|r.delete_object()}
        end
      end
    end

    def add_node(node_template_idh,node_name)
      node_template = node_template_idh.create_object()
      target = get_target()
      #TODO: see if node name used in assembly already and if so add -n suffix
      override_attrs = {
        :display_name => node_name,
        :assembly_id => id(),
      }
      clone_opts = node_template.source_clone_info_opts()
      new_obj = target.clone_into(node_template,override_attrs,clone_opts)
      new_obj && new_obj.id_handle()
    end

    def add_component(node_idh,component_template_idh,order_index=nil)
      #first check that node_idh belongs to this instance
      sp_hash = {
        :cols => [:id, :display_name,:group_id, :ordered_component_ids],
        :filter => [:and, [:eq, :id, node_idh.get_id()], [:eq, :assembly_id, id()]]
      }
      unless node = Model.get_obj(model_handle(:node),sp_hash)
        raise ErrorIdInvalid.new(node_idh.get_id(),:node)
      end

      # Checking if 'order_index' is valid (number and correct value)
      order = node.get_ordered_component_ids()
      raise ErrorUsage, "Invalid value for DEPENDENCY-ORDER-INDEX: '#{order_index}'" unless is_order_index_valid(order_index, order)

      component = node.add_component(component_template_idh)

      # Amar: updating order; if 'order_index' nil push to end, otherwise insert into current array
      if order_index.nil?
        order.push(component[:guid])
      else
        order.insert(order_index.to_i, component[:guid])
      end
      node.update_ordered_component_ids(order)
      return component
    end

    def is_order_index_valid(order_index, order)
      return ((order_index && order_index.to_i.to_s == order_index && order_index.to_i <= order.size && order_index.to_i > -1) || order_index.nil? || order_index.empty?)
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
        :cols => [:id, :display_name, :node_node_id],
        :filter => component_filter
      }
      component = Model.get_obj(model_handle(:component),sp_hash)
      unless component
        raise ErrorIdInvalid.new(component_idh.get_id(),:component)
      end
      
      Model.delete_instance(component_idh)
      
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

    def create_new_template(service_module,new_template_name)
      service_module_name = service_module.get_field?(:display_name)
      project = service_module.get_project()
      if Assembly::Template.exists?(project.id_handle(),service_module_name,new_template_name)
        raise ErrorUsage.new("Assembly template (#{new_template_name}) already exists in service module (#{service_module_name})")
      end

      name_info = {
        :service_module_name => service_module_name,
        :assembly_template_name => new_template_name
      }
      create_assembly_template_from_instance(project,name_info)
    end      

    def get_attributes_print_form(opts=Opts.new)
      if filter = opts[:filter]
        case filter
          when :required_unset_attributes
            filter_proc = lambda{|r|r[:attribute].required_unset_attribute?()}
            opts.merge!(:filter_proc => filter_proc)
          else 
            raise Error.new("not treating filter (#{filter}) in Assembly::Instance#get_attributes_print_form")
        end  
      end
      get_attributes_print_form_aux(opts)
    end

    def get_attributes_print_form_aux(opts=Opts.new)
      filter_proc = opts[:filter_proc]
      assembly_attrs = get_assembly_level_attributes(filter_proc).map do |attr|
        attr.print_form(opts.merge(:level => :assembly))
      end

      raw_cmp_attrs = get_augmented_nested_component_attributes(filter_proc)
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

    def create_assembly_template_from_instance(project,name_info=nil)
      if name_info
        service_module_name = name_info[:service_module_name]
        template_name = name_info[:assembly_template_name]
      else
        component_type = get_field?(:component_type)
        service_module_name,template_name = Assembly::Template.parse_component_type(component_type)
      end
      node_idhs = get_nodes().map{|r|r.id_handle()}
      if node_idhs.empty?
        raise Error.new("Cannot find any nodes associated with assembly (#{get_field?(:display_name)})")
      end
      Assembly::Template.create_from_instance(project,node_idhs,template_name,service_module_name)
    end
  end
end 
#TODO: hack to get around error in /home/dtk/server/system/model.r8.rb:31:in `const_get
AssemblyInstance = Assembly::Instance
end

