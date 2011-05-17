module XYZ
  class Task < Model

    def self.create_from_nodes_to_rerun(node_idhs)
      config_nodes_task = config_nodes_task(grouped_state_changes[TaskAction::ConfigNode])
      if create_nodes_task and config_nodes_task
        ret = create_new_task(:temporal_order => "sequential")
        ret.add_subtask(create_nodes_task)
        ret.add_subtask(config_nodes_task)
        ret
      else
        ret = create_new_task(:temporal_order => "sequential")
        ret.add_subtask(create_nodes_task||config_nodes_task) #only one wil be non null
        ret
      end
    end


    def self.get_top_level_tasks(model_handle)
      sp_hash = {
        :cols => [:id,:display_name,:status,:updated_at,:executable_action_type],
        :filter => [:eq,:task_id,nil] #so this is a top level task
      }
      get_objects_from_sp_hash(model_handle,sp_hash).reject{|k,v|k == :subtasks}
    end


    def get_associated_nodes()
      exec_actions = Array.new
      #if executable level then get its executable_action
      if self.has_key?(:executable_action_type) 
        #will have an executable action so if have it already
        if self[:executable_action_type]
          exec_actions << self[:executable_action] || get_objects_col_from_sp_hash(:cols=>[:executable_action]).first
        end
      else
        exec_action = get_objects_col_from_sp_hash(:cols=>[:executable_action]).first
        exec_actions <<  exec_action if exec_action
      end

      #if task does not have execuatble actions then get all subtasks
      if exec_actions.empty?
        exec_actions = get_all_subtasks().map{|t|t[:executable_action]}.compact
      end
      
      #get all unique nodes; looking for attribute :external_ref
      indexed_nodes = Hash.new
      exec_actions.each do |ea|
        next unless node = ea[:node]
        node_id = node[:id]
        unless indexed_nodes[node_id] and indexed_nodes[node_id][:external_ref]
          indexed_nodes[node_id] = node
        end
      end

      #need to query db if missing external_refs
      node_ids_missing_ext_refs = indexed_nodes.values.reject{|n|n[:external_ref]}.map{|n|n[:id]}
      unless node_ids_missing_ext_refs.empty?
        sp_hash = {
          :cols => [:id,:external_ref],
          :filter => [:oneof, :id, node_ids_missing_ext_refs]
        }
        node_mh = model_handle.createMH(:node)
        node_objs = Model.get_objects_from_sp_hash(node_mh,sp_hash)
        node_objs.each{|r|indexed_nodes[r[:id]][:external_ref] = r[:external_ref]}
      end
      indexed_nodes.values
    end

    #recursively walks structure, but returns them in flat list
    def get_all_subtasks()
      ret = Array.new
      id_handles = [id_handle]

      until id_handles.empty?
        sp_hash = {
        :cols => [:id,:display_name,:status,:updated_at,:task_id,:executable_action_type,:executable_action],
          :filter => [:oneof,:task_id,id_handles.map{|idh|idh.get_id}] 
        }
        next_level_objs = Model.get_objects_from_sp_hash(model_handle,sp_hash).reject{|k,v|k == :subtasks}
        id_handles = next_level_objs.map{|obj|obj.id_handle}
        ret += next_level_objs
      end
      ret
    end

    def ret_command_and_control_adapter_info()
      #TODO: stub
      [:node_config,nil]
    end

    def initialize(hash_scalar_values,c,model=:task)
      defaults = { 
        :status => "created",
        :action_on_failure => "abort"
      }
      super(defaults.merge(hash_scalar_values),c,model)
      self[:subtasks] = Array.new
    end

    #persists to db this and its sub tasks
    def save!()
      #no op if saved already as detected by whether has an id
     return nil if id()
      set_positions!()
      #for db access efficiency implement into two phases: 1 - save all subtasks w/o ids, then put in ids
      unrolled_tasks = unroll_tasks()
      rows = unrolled_tasks.map do |hash_row|
        executable_action = hash_row[:executable_action]
        row = {
          :display_name => "task#{hash_row[:position].to_s}",
          :ref => "task#{hash_row[:position].to_s}",
          :executable_action_type => executable_action ? Aux.demodulize(executable_action.class.to_s) : nil,
          :executable_action => executable_action
        }
        cols = [:status, :result, :action_on_failure, :position, :temporal_order] 
        cols.each{|col|row.merge!(col => hash_row[col])}
        row
      end
      id_info_list = Model.create_from_rows(model_handle,rows,{:convert => true,:do_not_update_info_table => true})
      #set ids
      unrolled_tasks.each_with_index{|task,i|task.set_id_handle(id_info_list[i])}

      #set parent relationship
      par_rel_rows_for_id_info = set_and_ret_parents!()
      par_rel_rows_for_task = par_rel_rows_for_id_info.map{|r|{:id => r[:id], :task_id => r[:parent_id]}}

      #prune top level tasks
      par_rel_rows_for_task.reject!{|r|r[:task_id].nil?}
      Model.update_from_rows(model_handle,par_rel_rows_for_task) unless par_rel_rows_for_task.empty?
      IDInfoTable.update_instances(model_handle,par_rel_rows_for_id_info)
    end

    def subtasks()
      self[:subtasks]
    end

    #for special tasks that have component actions
    #TODO: trie dto do this by having a class inherir from Task and hanging these fns off it, but this confused Ramaze
    def component_actions()
      if self[:executable_action].kind_of?(TaskAction::ConfigNode)
        action = self[:executable_action]
        return (action[:component_actions]||[]).map{|ca| action[:node] ? ca.merge(:node => action[:node]) : ca}
      end
      subtasks.map{|obj|obj.component_actions()}.flatten
    end


    def add_subtask_from_hash(hash)
      defaults = {:status => "created", :action_on_failure => "abort"}
      new_subtask = Task.new(defaults.merge(hash),c)
      add_subtask(new_subtask)
    end

    def add_subtask(new_subtask)
      self[:subtasks] << new_subtask
      new_subtask
    end

    def set_positions!()
      self[:position] ||= 1
      return nil if subtasks.empty?
      subtasks.each_with_index do |e,i|
        e[:position] = i+1
        e.set_positions!()
      end
    end

    def set_and_ret_parents!(parent_id=nil)
      self[:task_id] = parent_id
      id = id()
      [:parent_id => parent_id, :id => id] + subtasks.map{|e|e.set_and_ret_parents!(id)}.flatten
    end

    def unroll_tasks()
      [self] + subtasks.map{|e|e.unroll_tasks()}.flatten
    end

    #### for rending tasks
   public
    def render_form()
      #may be different forms; this is one that is organized by node_group, node, component, attribute
      task_list = render_form_flat(true)
      #TODO: not yet teating node_group
      
      Task.render_group_by_node(task_list)
    end

   protected
    #protected, not private, because of recursive call 
     def render_form_flat(top=false)
      #prune out all (sub)tasks except for top and  executable 
      return render_executable_tasks() if self[:executable_action]
      (top ? [render_top_task()] : []) + subtasks.map{|e|e.render_form_flat()}.flatten
    end

   private
    def self.render_group_by_node(task_list)
      return task_list if task_list.size < 2
      ret = nil
      indexed_nodes = Hash.new
      task_list.each do |t|
        if t[:level] == "top"
          ret = t
        elsif t[:level] == "node"
          indexed_nodes[t[:node_id]] = t
        end
      end
      task_list.each do |t|
        if t[:level] == "node"
          ret[:children] << t
        elsif t[:level] == "component"
          if indexed_nodes[t[:node_id]]
            indexed_nodes[t[:node_id]][:children] << t
          else
            node_task = Task.render_task_on_node(:node_id => t[:node_id], :node_name => t[:node_name]) 
            node_task[:children] << t
            ret[:children] << node_task
            indexed_nodes[node_task[:node_id]] = node_task
          end
        end
      end
      ret
    end

    def render_top_task()
      {:task_id => id(),
        :level => "top",
        :type => "top",
        :action_on_failure=> self[:action_on_failure],
        :children => Array.new
      }
    end

    def render_executable_tasks()
      executable_action = self[:executable_action]
      sc = executable_action[:state_change_types]
      common_vals = {
        :task_id => id(),
        :status => self[:status],
      }
      #order is important
      if sc.include?("create_node") then Task.render_tasks_create_node(executable_action,common_vals)
      elsif sc.include?("install_component") then Task.render_tasks_component_op("install_component",executable_action,common_vals)
      elsif sc.include?("setting") then Task.render_tasks_setting(executable_action,common_vals)
      elsif sc.include?("update_implementation") then Task.render_tasks_component_op("update_implementation",executable_action,common_vals)
      elsif sc.include?("rerun_component") then Task.render_tasks_component_op("rerun_component",executable_action,common_vals)
      else 
        Log.error("do not treat executable tasks of type(s) #{sc.join(',')}")
        nil
      end
    end

    def self.render_task_on_node(node_info)
      {:type => "on_node",
        :level => "node",
        :children => Array.new
      }.merge(node_info)
    end

    def self.render_tasks_create_node(executable_action,common_vals)
      node = executable_action[:node]
      task = {
        :type => "create_node",
        :level => "node",
        :node_id => node[:id],
        :node_name => node[:display_name],
        :image_name => executable_action[:image][:display_name],
        :children => Array.new
      }
      [task.merge(common_vals)]
    end

    def self.render_tasks_component_op(type,executable_action,common_vals)
      node = executable_action[:node]
      (executable_action[:component_actions]||[]).map do |component_action|
        component = component_action[:component]
        cmp_attrs = {
          :component_id => component[:id],
          :component_name => component[:display_name]
        }
        task = {
          :type => type,
          :level => "component",
          :node_id => node[:id],
          :node_name => node[:display_name],
          :component_basic_type => component[:basic_type]
        }
        task.merge!(cmp_attrs)
        task.merge!(common_vals)
        add_attributes_to_component_task!(task,component_action,cmp_attrs)
      end
    end

    def self.render_tasks_setting(executable_action,common_vals)
      node = executable_action[:node]
      (executable_action[:component_actions]||[]).map do |component_action|
        component = component_action[:component]
        cmp_attrs = {
          :component_id => component[:id],
          :component_name => component[:display_name].gsub(/::/,"_")
        }
        task = {
          :type => "on_component",
          :level => "component",
          :node_id => node[:id],
          :node_name => node[:display_name],
          :component_basic_type => component[:basic_type]
        }
        task.merge!(cmp_attrs)
        task.merge!(common_vals)
        add_attributes_to_component_task!(task,component_action,cmp_attrs)
      end
    end

    def self.add_attributes_to_component_task!(task,component_action,cmp_attrs)
      attributes = component_action[:attributes]
      return task unless attributes
      keep_ids = component_action[:changed_attribute_ids]
      pruned_attrs = attributes.reject do |a|
        a[:hidden] or (keep_ids and not keep_ids.include?(a[:id]))
      end
      flattten_attrs = AttributeComplexType.flatten_attribute_list(pruned_attrs)
      flattten_attrs.each do |a|
        val = a[:attribute_value]
        if val.nil?
          next unless a[:port_type] == "input" and a[:required]
          val = "DYNAMICALLY SET"
        end
        attr_task = {
          :type => "setting",
          :level => "attribute",
          :attribute_id => a[:id],
          :attribute_name => a[:display_name],
          :attribute_value => val,
          :attribute_data_type => a[:data_type],
          :attribute_required => a[:required],
          :attribute_dynamic => a[:dynamic]
        }
        attr_task.merge!(cmp_attrs)
        task[:children]||= Array.new
        task[:children] << attr_task
      end
      task
    end
  end
end


