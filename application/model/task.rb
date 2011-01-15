module XYZ
  class Task < Model
    set_relation_name(:task,:task)
    def self.up()
      column :status, :varchar, :size => 20, :default => "created" # = "created" | "in_progres" | "completed"
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
      super(hash_scalar_values,c,model)
      @elements = Array.new
    end

    def self.create_top_level(c,temporal_order)
      hash = {
        :status => "created",
        :action_on_failure => "abort",
        :temporal_order => temporal_order
      } 
      Task.new(hash,c)
    end

    #persists to db this and its sub tasks
    def save!()
      #no op if sabved already as detected by whether has an id
     return nil if id()
      set_positions!()
      #for db access efficiency implement into two phases: 1 - save all subtasks w/o ids, then point in ids
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
      Model.update_from_rows(model_handle,par_rel_rows_for_task)
      IDInfoTable.update_instances(model_handle,par_rel_rows_for_id_info)
    end

    attr_reader :elements

    #for special tasks that have component actions
    #TODO: trie dto do this by having a class inherir from Task and hanging these fns off it, but this confused Ramaze
    def component_actions()
      if self[:executable_action].kind_of?(TaskAction::ConfigNode)
        return self[:executable_action][:component_actions]||[]
      end
      elements.map{|obj|obj.component_actions()}.flatten
    end


    def add_subtask(hash)
      defaults = {:status => "created", :action_on_failure => "abort"}
      new_subtask = Task.new(hash.merge(defaults),c)
      @elements << new_subtask
      new_subtask
    end

    def set_positions!()
      self[:position] ||= 1
      return nil if elements.empty?
      elements.each_with_index do |e,i|
        e[:position] = i+1
        e.set_positions!()
      end
    end

    def set_and_ret_parents!(parent_id=nil)
      self[:task_id] = parent_id
      id = id()
      [:parent_id => parent_id, :id => id] + elements.map{|e|e.set_and_ret_parents!(id)}.flatten
    end

    def unroll_tasks()
      [self] + elements.map{|e|e.unroll_tasks()}.flatten
    end
  end
end


