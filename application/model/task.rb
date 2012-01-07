r8_nested_require('task','create')
r8_nested_require('task','action')
module XYZ
  class Task < Model
    extend TaskCreateClassMixin
    #for debugging
    def pretty_print_hash()
      ret = PrettyPrintHash.new
      ret.add(self,:id,:status)
      num_subtasks = subtasks.size
      #only include :temporal_order if more than 1 subtask
      ret.add(self,:temporal_order) if num_subtasks > 1
      if num_subtasks > 0
        ret.add(self,:subtasks) do |subtasks|
          subtasks.sort{|a,b| (a[:position]||0) <=> (b[:position]||0)}.map{|st|st.pretty_print_hash()}
        end
      end
      action_type = self[:executable_action_type]
      case action_type
       when "ConfigNode" 
        ret.add(self,:executable_action_type)
        ret.add(self,:executable_action?){|ea|TaskAction::ConfigNode.pretty_print_hash(ea)}
       when "CreateNode" 
        ret.add(self,:executable_action_type)
        ret.add(self,:executable_action?){|ea|TaskAction::CreateNode.pretty_print_hash(ea)}
       else
        ret.add(self,:executable_action_type?,:executable_action?)
      end
      ret
    end

    #TODO: cleanup; quick hack
    def state_info()
      set_and_return_names!()
      ret = PrettyPrintHash.new
      ret.add(self,:name,:id,:status)
      num_subtasks = subtasks.size
      ret.add(self,:temporal_order) if num_subtasks > 1
      if num_subtasks > 0
        ret.add(self,:subtasks) do |subtasks|
          subtasks.sort{|a,b| (a[:position]||0) <=> (b[:position]||0)}.map{|st|st.state_info()}
        end
      end
      action_type = self[:executable_action_type]
      case action_type
       when "ConfigNode" 
        if ea = self[:executable_action]
          ret.merge!(TaskAction::ConfigNode.state_info(ea))
        end
       when "CreateNode" 
        if ea = self[:executable_action]
          ret.merge!(TaskAction::CreateNode.state_info(ea))
        end
      end
      ret
    end

    #TODO: a hack
    #TODO: probably better to get this from display_name and set when creating
    def set_and_return_names!()
      name = nil
      if self[:task_id].nil?
        name = "top"
      else
        if action_type = self[:executable_action_type]
          name = ActionTypeNames[action_type.to_s]
        else
          #assumption that all subtypes some type
          if sample_st = subtasks.first
            if sample_st[:executable_action_type]
              sample_type = ActionTypeNames[sample_st[:executable_action_type]]
              name = (sample_type && "#{sample_type}s") #make plural
            end
          end 
        end
      end
      subtasks.each{|st|st.set_and_return_names!()}
      self[:name] = name
    end
    protected :set_and_return_names!

    ActionTypeNames = {
      "ConfigNode" => "Configure Node",
      "CreateNode" => "Create Node"
    }
    
    def get_events()
      sp_hash = {:cols => [:created_at, :type, :content]}
      get_children_objs(:task_event,sp_hash).sort{|a,b| a[:created_at] <=> b[:created_at]}
    end

    def add_event(event_type,result=nil)
      event = TaskEvent.create_event?(event_type,self,result)
      return nil unless event
      type = event.delete(:type)||event_type
      row = {
        :content => event.to_hash, 
        :ref => "task_event", 
        :type => type.to_s,
        :task_id => id()
      }
      Model.create_from_rows(model_handle(:task_event),[row],{:convert => true})
      event
    end
    
    #returns [event,error-array]
    def add_event_and_errors(event_type,result=nil)
      ret = [nil,nil]
      #process errors and strip out from what is passed to add event
      #TODO: change client so just returns :errors not sither :error or :errors
      error = ((result||{})[:data]||{})[:error]
      if errors_in_result = (error ? [error] : ((result||{})[:data]||{})[:errors])
        config_agent = get_config_agent
        components = component_actions().map{|a|a[:component]}
        normalized_errors = errors_in_result.map{|err|config_agent.interpret_error(err,components)}
        ret[1] = add_errors(normalized_errors)
        result_wo_errors = result.dup[:data]
        result_wo_errors.delete(:errors)
      else
        result_wo_errors = result
      end
      ret[0] = add_event(event_type,result_wo_errors)
      ret
    end

    def add_errors(normalized_errors)
      ret = nil
      return ret unless normalized_errors and not normalized_errors.empty?
      rows = normalized_errors.map do |err|
        {
          :content => err,
          :ref => "task_error", 
          :task_id => id()
        }
      end
      Model.create_from_rows(model_handle(:task_error),rows,{:convert => true})
      normalized_errors 
    end

    #this updates self, which is leaf node, plus all parents
    def update(update_hash,opts={})
      super(update_hash)
      unless opts[:no_hierarchical_update_status]
        hierarchical_update_status(update_hash[:status]) if update_hash[:status]
      end
    end

    def hierarchical_update_status(status)
      update_object!(:task_id)
      if self[:task_id]
        parent = id_handle.createIDH(:id => self[:task_id]).create_object().update_object!(:status,:children_status)
        key = id().to_s.to_sym #TODO: look at avoiding this by having translation of json not make num keys into symbols
        parent[:children_status][key] = status
        parent.update_from_children_status()
      end
    end
    def update_from_children_status()
      children_status = self[:children_status]
      subtask_status_array = children_status.values
      new_status = 
        if subtask_status_array.include?("failed") then "failed"
        elsif subtask_status_array.include?("executing") then "executing"
        elsif not subtask_status_array.find{|s|s != "succeeded"} then "succeeded" #all succeeded
        else "executing" #if reach here must be some created and some finished
        end
      hier_update = (new_status != self[:status])
      update({:status => new_status, :children_status => children_status},{:no_hierarchical_update_status => (not hier_update)})
    end
    private :hierarchical_update_status
    protected :update_from_children_status

    def update_input_attributes!()
      task_action = self[:executable_action]
      #updates ruby task object
      task_action.get_and_update_attributes!(self)
    end

    def add_internal_guards!(guards)
      task_action = self[:executable_action]
      #updates ruby task object
      task_action.add_internal_guards!(guards)
    end

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
        :cols => [:id,:group_id,:display_name,:status,:updated_at,:executable_action_type],
        :filter => [:eq,:task_id,nil] #so this is a top level task
      }
      get_objs(model_handle,sp_hash).reject{|k,v|k == :subtasks}
    end

    def self.get_most_recent_top_level_task(model_handle)
      get_top_level_tasks(model_handle).sort{|a,b| b[:updated_at] <=> a[:updated_at]}.first
    end

    def get_per_node_info_for_reporting()
      exec_actions = Array.new
      #if executable level then get its executable_action
      if self.has_key?(:executable_action_type) 
        #will have an executable action so if have it already
        if self[:executable_action_type]
          exec_actions << update_object!(:executable_action)[:executable_action]
        end
      else
        if exec_action = update_object!(:executable_action)[:executable_action]
          exec_actions <<  exec_action.merge(:task_id => id())
        end
      end

      #if task does not have execuatble actions then get all subtasks
      if exec_actions.empty?
        exec_actions = get_all_subtasks().map do |t|
          action = t[:executable_action]
          action && action.merge(:task_id => t.id())
        end.compact
      end
      
      #get all unique nodes; looking for attribute :external_ref
      indexed_nodes = Hash.new
      exec_actions.each do |ea|
        next unless node = ea[:node]
        node_id = node[:id]
        indexed_nodes[node_id] ||= node.merge(:task_id => ea[:task_id])
        indexed_nodes[node_id][:external_ref] ||= node[:external_ref]
        indexed_nodes[node_id][:config_agent_type] ||= get_config_agent_type(ea)
      end

      #need to query db if missing external_refs having instance_id
      node_ids_missing_ext_refs = indexed_nodes.values.reject{|n|(n[:external_ref]||{})[:instance_id]}.map{|n|n[:id]}
      unless node_ids_missing_ext_refs.empty?
        sp_hash = {
          :cols => [:id,:external_ref],
          :filter => [:oneof, :id, node_ids_missing_ext_refs]
        }
        node_mh = model_handle.createMH(:node)
        node_objs = Model.get_objs(node_mh,sp_hash)
        node_objs.each{|r|indexed_nodes[r[:id]][:external_ref] = r[:external_ref]}
      end
      indexed_nodes.values
    end

    #TODO: may deprecate below and subsume by above
    #this also provides the nodes task_id and config_agent_type as extra attribute values
    def get_associated_nodes()
      exec_actions = Array.new
      #if executable level then get its executable_action
      if self.has_key?(:executable_action_type) 
        #will have an executable action so if have it already
        if self[:executable_action_type]
          exec_actions << update_object!(:executable_action)[:executable_action]
        end
      else
        if exec_action = update_object!(:executable_action)[:executable_action]
          exec_actions <<  exec_action.merge(:task_id => id())
        end
      end

      #if task does not have execuatble actions then get all subtasks
      if exec_actions.empty?
        exec_actions = get_all_subtasks().map do |t|
          action = t[:executable_action]
          action && action.merge(:task_id => t.id())
        end.compact
      end
      
      #get all unique nodes; looking for attribute :external_ref
      indexed_nodes = Hash.new
      exec_actions.each do |ea|
        next unless node = ea[:node]
        node_id = node[:id]
        indexed_nodes[node_id] ||= node.merge(:task_id => ea[:task_id])
        indexed_nodes[node_id][:external_ref] ||= node[:external_ref]
        indexed_nodes[node_id][:config_agent_type] ||= get_config_agent_type(ea)
      end

      #need to query db if missing external_refs having instance_id
      node_ids_missing_ext_refs = indexed_nodes.values.reject{|n|(n[:external_ref]||{})[:instance_id]}.map{|n|n[:id]}
      unless node_ids_missing_ext_refs.empty?
        sp_hash = {
          :cols => [:id,:external_ref],
          :filter => [:oneof, :id, node_ids_missing_ext_refs]
        }
        node_mh = model_handle.createMH(:node)
        node_objs = Model.get_objs(node_mh,sp_hash)
        node_objs.each{|r|indexed_nodes[r[:id]][:external_ref] = r[:external_ref]}
      end
      indexed_nodes.values
    end

    def get_config_agent_type(executable_action=nil)
      executable_action ||= self[:executable_action]
      #just takes one sample since assumes all component actions have same config agent
      ((executable_action[:component_actions]||[]).first||{})[:on_node_config_agent_type]
    end
    def get_config_agent()
      ConfigAgent.load(get_config_agent_type())
    end
    private :get_config_agent_type, :get_config_agent

    #recursively walks structure, but returns them in flat list
    def get_all_subtasks(opts={})
      detail_level = opts[:detail_level] || :detailed
      ret = Array.new
      id_handles = [id_handle]

      until id_handles.empty?
        sp_hash = {
          :cols => Task.common_columns(),
          :filter => [:oneof,:task_id,id_handles.map{|idh|idh.get_id}] 
        }
        next_level_objs = Model.get_objs(model_handle,sp_hash).reject{|k,v|k == :subtasks}

        #process depending on detail level
        if detail_level == :detailed
          next_level_objs.each{|st|st.reify!()}
        else
          next_level_objs.each{|st|st.prune_for_summary!()}
        end
        id_handles = next_level_objs.map{|obj|obj.id_handle}

        ret += next_level_objs
      end
      ret
    end
    def prune_for_summary!()
      TaskAction::TaskActionNode.prune_for_summary!(self[:executable_action_type],self[:executable_action]) if self[:executable_action]
    end
    def reify!()
      self[:executable_action] &&= TaskAction::TaskActionNode.create_from_hash(self[:executable_action_type],self[:executable_action],id_handle)
    end
    protected :prune_for_summary!,:reify!

    def self.get_hierarchical_structure(top_task_idh,opts={})
      sp_hash = {
        :cols => Task.common_columns(),
        :filter => [:eq,:id,top_task_idh.get_id()]
      }
      top_task = get_objs(top_task_idh.createMH(),sp_hash).first
      flat_subtask_list = top_task.get_all_subtasks(opts)
      ndx_task_list = flat_subtask_list.inject({top_task.id => top_task}){|h,t|h.merge(t.id => t)}
      flat_subtask_list.each do |subtask|
        parent_id = subtask[:task_id]
        (ndx_task_list[parent_id][:subtasks] ||= Array.new) << subtask
      end
      top_task
    end

    def self.common_columns()
      [
       :id,
       :display_name,
       :status,
       :result,
       :updated_at,
       :created_at,
       :start_datetime,
       :end_datetime,
       :task_id,
       :temporal_order,
       :position,
       :executable_action_type,
       :executable_action
      ]
    end

    def ret_command_and_control_adapter_info()
      #TODO: stub
      [:node_config,nil]
    end

    def initialize(hash_scalar_values,c,model=:task,id_handle=nil)
      defaults = { 
        :status => "created",
        :action_on_failure => "abort"
      }
      super(defaults.merge(hash_scalar_values),c,model,id_handle)
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
          #TODO: put in the user friendly name
          :display_name => "task#{hash_row[:position].to_s}",
          :ref => "task#{hash_row[:position].to_s}",
          :executable_action_type => executable_action ? Aux.demodulize(executable_action.class.to_s) : nil,
          :executable_action => executable_action
        }
        cols = [:status, :result, :action_on_failure, :position, :temporal_order] 
        cols.each{|col|row.merge!(col => hash_row[col])}
        row
      end
      new_idhs = Model.create_from_rows(model_handle,rows,{:convert => true,:do_not_update_info_table => true})
      #set ids
      unrolled_tasks.each_with_index{|task,i|task.set_id_handle(new_idhs[i])}

      #set parent relationship and use to set task_id (subtask parent) and children_status
      par_rel_rows_for_id_info = set_and_ret_parents_and_children_status!()
      par_rel_rows_for_task = par_rel_rows_for_id_info.map{|r|{:id => r[:id], :task_id => r[:parent_id], :children_status => r[:children_status]}}
      
      Model.update_from_rows(model_handle,par_rel_rows_for_task) unless par_rel_rows_for_task.empty?
      IDInfoTable.update_instances(model_handle,par_rel_rows_for_id_info)
    end

    def subtasks()
      self[:subtasks]||[]
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

    def set_and_ret_parents_and_children_status!(parent_id=nil)
      self[:task_id] = parent_id
      id = id()
      if subtasks.empty?
        [:parent_id => parent_id, :id => id, :children_status => nil]
      else
        recursive_subtasks = subtasks.map{|st|st.set_and_ret_parents_and_children_status!(id)}.flatten
        children_status = subtasks.inject({}){|h,st|h.merge(st.id() => "created")}
        [:parent_id => parent_id, :id => id, :children_status => children_status] + recursive_subtasks 
      end
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


