module DTK; class  Assembly
  class Instance
    module ListClassMixin
      def list_with_workspace(assembly_mh,opts={})
        target_idh = opts[:target_idh]
        target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id()] : [:neq, :datacenter_datacenter_id, nil])
        filter = [:and, [:eq, :type, "composite"], target_filter,opts[:filter]].compact
        
        sp_hash = {
          :cols => [:id, :display_name].compact,
          :filter => filter
        }
        get_objs(assembly_mh.createMH(:assembly_instance),sp_hash)
      end

      def list(assembly_mh,opts={})
        assembly_mh = assembly_mh.createMH(:assembly_instance) # to insure right mh type
        assembly_rows = get_info__flat_list(assembly_mh,opts)
        assembly_rows.reject!{|r|Workspace.is_workspace?(r)} unless opts[:include_workspace]

        if opts[:detail_level].nil?
          list_aux__no_details(assembly_rows)
        else
          get_attrs = [opts[:detail_level]].flatten.include?("attributes")
          attr_rows = get_attrs ? get_default_component_attributes(assembly_mh,assembly_rows) : []
          add_last_task_run_status!(assembly_rows,assembly_mh)
        
          list_aux(assembly_rows,attr_rows,opts)
        end
      end

      def pretty_print_name(assembly,opts={})
        assembly.get_field?(:display_name)
      end

     private
      def list_aux__no_details(assembly_rows)
        assembly_rows.map do |r|
          r.prune_with_values(:display_name => pretty_print_name(r))
        end
      end

      def add_last_task_run_status!(assembly_rows,assembly_mh)
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
        assembly_rows.each do |r|
          if node = r[:node]
            if last_task_run_status = ndx_task_rows[r[:id]] && ndx_task_rows[r[:id]][:status]
              r[:last_task_run_status] = last_task_run_status
            end
          end
        end
        assembly_rows
      end

    end

    module ListMixin
      def info_about(about,opts=Opts.new)
        case about 
        when :attributes
          list_attributes(opts)
        when :components
          list_components(opts)
        when :nodes
          list_nodes(opts)
        when :modules
          list_component_modules(opts)
        when :tasks
          list_tasks(opts)
        else
          raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")
        end
      end

      def list_attributes(opts)
        if opts[:settings_form]
          ServiceSetting::AttributeSettings.get_and_render_in_hash_form(self)
        else
          cols_to_get = (opts[:raw_attribute_value] ? [:display_name,:value] : [:id,:display_name,:value,:linked_to_display_form,:datatype,:name])
          ret = get_attributes_print_form_aux(opts).map do |a|
            Aux::hash_subset(a,cols_to_get)
          end.sort{|a,b| a[:display_name] <=> b[:display_name] }
          opts[:raw_attribute_value] ? ret.inject(Hash.new){|h,r|h.merge(r[:display_name] => r[:value])} : ret
        end
      end

      def list_component_modules(opts=Opts.new)
        component_modules_opts = Hash.new
        if get_version_info = opts.array(:detail_to_include).include?(:version_info)
          opts.set_datatype!(:assembly_component_module)
          component_modules_opts.merge!(:get_version_info=>true)
        end
        unsorted_ret = get_component_modules(component_modules_opts)
          if get_version_info
            unsorted_ret.each do |r|
            if r[:local_copy]
              r[:update_saved] = !r[:local_copy_diff]
            end
          end
        end
        unsorted_ret.sort{|a,b| a[:display_name] <=> b[:display_name] }
      end

      def list_nodes(opts=Opts.new)
        nodes = get_nodes__expand_node_groups()
        nodes.each do |node|
          set_node_display_name!(node)
          set_node_admin_op_status!(node)
          if external_ref = node[:external_ref]
            external_ref[:dns_name] ||= external_ref[:routable_host_address] #TODO: should be cleaner place to put this
          end
          node.sanitize!()
        end
        nodes.sort{|a,b| a[:display_name] <=> b[:display_name] }
      end
      private :list_nodes
      def set_node_display_name!(node)
        node[:display_name] = node.assembly_node_print_form()
      end
      def set_node_admin_op_status!(node)
        if node.is_node_group?()
          node[:admin_op_status] = nil
        end
      end
      private :set_node_display_name!,:set_node_admin_op_status!

      def list_components(opts=Opts.new)
        aug_cmps = get_augmented_components(opts)
        node_cmp_name = opts[:node_cmp_name]
        cmps_print_form = aug_cmps.map do |r|
          namespace = r[:namespace]
          node_name = "#{r[:node][:display_name]}/"
          display_name = "#{node_cmp_name.nil? ? node_name : ''}#{Component::Instance.print_form(r, namespace)}"
          r.hash_subset(:id).merge({:display_name => display_name})
        end
      
        sort = proc{|a,b|a[:display_name] <=> b[:display_name]}
        if opts.array(:detail_to_include).include?(:component_dependencies)
          opts.set_datatype!(:component_with_dependencies)
          list_components__with_deps(cmps_print_form,aug_cmps,sort)
        else
          opts.set_datatype!(:component)
          cmps_print_form.sort(&sort)
        end
      end

      def display_name_print_form(opts={})
        pretty_print_name()
      end

      def list_smoketests()
        Log.error("TODO: needs to be tested")
        nodes_and_cmps = get_info__flat_list(:detail_level => "components")
        nodes_and_cmps.map{|r|r[:nested_component]}.select{|cmp|cmp[:basic_type] == "smoketest"}.map{|cmp|Aux::hash_subset(cmp,[:id,:display_name,:description])}
      end

     private
      def list_tasks(opts={})
        tasks = []
        rows = get_objs(:cols => [:tasks])
        rows.each do |row|
          task = row[:task]
          task_obj_idh = task.id_handle()
          task_mh = task_obj_idh.createMH(:task)
          task_structure = Task.get_hierarchical_structure(task_mh.createIDH(:id => task[:id]))
          status_opts = {}
          tasks << task_structure.status_table_form(status_opts)
        end
        tasks.flatten
      end

      def list_components__with_deps(cmps_print_form,aug_cmps,main_table_sort)
        ndx_component_print_form = ret_ndx_component_print_form(aug_cmps,cmps_print_form)
        join_columns = OutputTable::JoinColumns.new(aug_cmps) do |aug_cmp|
          if deps = aug_cmp[:dependencies]
            ndx_els = Hash.new
            deps.each do |dep|
              if depends_on = dep.depends_on_print_form?()
                el = ndx_els[depends_on] ||= Array.new
                sb_cmp_ids =  dep.satisfied_by_component_ids
                ndx_els[depends_on] += (sb_cmp_ids - el)
              end
            end
            ndx_els.map do |depends_on,sb_cmp_ids|
              satisfied_by = (sb_cmp_ids.empty? ? nil : sb_cmp_ids.map{|cmp_id|ndx_component_print_form[cmp_id]}.join(', '))
              {:depends_on => depends_on, :satisfied_by => satisfied_by}
            end
          end
        end
        OutputTable.join(cmps_print_form,join_columns,&main_table_sort)
      end

      def ret_ndx_component_print_form(aug_cmps,cmps_with_print_form)
        # has lookup that includes each satisfied_by_component
        ret = cmps_with_print_form.inject(Hash.new){|h,cmp|h.merge(cmp[:id] => cmp[:display_name])}
        
        # see if theer is any components that are nreferenced but not in ret
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

    end
  end
end; end
