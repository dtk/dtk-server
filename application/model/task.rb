module XYZ
  class Task < Model
    set_relation_name(:task,:task)
    def self.up()
      column :status, :varchar, :size => 20, :default => "created" # = "created" | "executing" | "completed" | "failed" | "not_reached"
      column :result, :json # gets serialized version of TaskAction::Result
      #column :output_vars, :json do we need this?
      #column :events, :json - content of this may instead go in result
      column :action_on_failure, :varchar, :default => "abort"

      column :temporal_order, :varchar, :size => 20 # = "sequential" | "concurrent"
      column :position, :integer, :default => 1

      column :executable_action_type, :varchar
      column :executable_action, :json # gets serialized version of TaskAction::Action
      many_to_one :task 
      one_to_many :task, :task_event, :task_error
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
      if sc.include?("create_node") then Task.render_tasks_create_node(executable_action,common_vals)
      elsif sc.include?("install_component") then Task.render_tasks_install_component(executable_action,common_vals)
      elsif sc.include?("setting") then Task.render_tasks_setting(executable_action,common_vals)
      else 
        Log.error("do not treat executable tasks of type(s) #{sc.join(',')}")
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

    def self.render_tasks_install_component(executable_action,common_vals)
      node = executable_action[:node]
      (executable_action[:component_actions]||[]).map do |component_action|
        component = component_action[:component]
        cmp_attrs = {
          :component_id => component[:id],
          :component_name => component[:display_name]
        }
        task = {
          :type => "install_component",
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
          next unless a[:port_type] == "input"
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


