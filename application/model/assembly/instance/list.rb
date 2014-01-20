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
        assembly_rows = get_info__flat_list(assembly_mh,opts)
        assembly_rows.reject!{|r|Workspace.is_workspace?(r)}
        if opts[:detail_level].nil?
          list_aux__no_details(assembly_rows)
        else
          get_attrs = [opts[:detail_level]].flatten.include?("attributes")
          attr_rows = get_attrs ? get_default_component_attributes(assembly_mh,assembly_rows) : []
          add_execution_status!(assembly_rows,assembly_mh)
        
          list_aux(assembly_rows,attr_rows,opts)
        end
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

    module ListMixin
      def info_about(about,opts=Opts.new)
        case about 
        when :attributes
          cols_to_get = (opts[:raw_attribute_value] ? [:display_name,:value] : [:id,:display_name,:value,:linked_to_display_form,:datatype,:name])
          ret = get_attributes_print_form_aux(opts).map do |a|
            Aux::hash_subset(a,cols_to_get)
          end.sort{|a,b| a[:display_name] <=> b[:display_name] }
          if opts[:raw_attribute_value]
            ret.inject(Hash.new){|h,r|h.merge(r[:display_name] => r[:value])}
          else
            ret
          end
        when :components
          list_components(opts)
          
        when :nodes
          get_nodes(:id,:display_name,:admin_op_status,:os_type,:external_ref,:type).sort{|a,b| a[:display_name] <=> b[:display_name] }
          
        when :modules
          component_modules_opts = Hash.new
          if opts.array(:detail_to_include).include?(:version_info)
            opts.set_datatype!(:assembly_component_module)
            component_modules_opts.merge!(:get_version_info=>true)
          end
          get_component_modules(component_modules_opts)
        when :tasks
          get_tasks(opts).sort{|a,b|(b[:started_at]||b[:created_at]) <=> (a[:started_at]||a[:created_at])} #TODO: might encapsulate in Task; ||foo[:created_at] used in case foo[:started_at] is null
          
        else
          raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")
        end
      end

      def list_components(opts=Opts.new)
        aug_cmps = get_augmented_components(opts)
        node_cmp_name = opts[:node_cmp_name]
        cmps_print_form = aug_cmps.map do |r|
          node_name = "#{r[:node][:display_name]}/"
          display_name = "#{node_cmp_name.nil? ? node_name : ''}#{Component::Instance.print_form(r)}"
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
      def list_components__with_deps(cmps_print_form,aug_cmps,main_table_sort)
        ndx_component_print_form = ret_ndx_component_print_form(aug_cmps,cmps_print_form)
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
        OutputTable.join(cmps_print_form,join_columns,&main_table_sort)
      end

      def ret_ndx_component_print_form(aug_cmps,cmps_with_print_form)
        #has lookup that includes each satisfied_by_component
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

    end
  end
end; end
