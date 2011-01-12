module XYZ
  class Task < Model
    set_relation_name(:task,:task)
    def self.up()
      column :status, :varchar, :size => 20, :default => "created" # = "created" | "in_progres" | "completed"
      column :position, :integer, :default => 1
      column :executable_action, :json
      column :temporal_order, :varchar, :size => 20 # = "sequential" | "concurrent"
      many_to_one :task 
      one_to_many :task, :task_event, :task_error
    end

    def self.create_top_level(c,temporal_order)
      hash = {
        :status => "created",
        :temporal_order => temporal_order
      } 
      Task.new(hash,c)
    end

    #for special tasks that have component actions
    #TODO: trie dto do this by having a class inherir from Task and hanging these fns off it, but this confused Ramaze
    def component_actions()
      if self[:executable_action].kind_of?(TaskAction::ConfigNode)
        return self[:executable_action][:component_actions]||[]
      end
      (@elements||[]).map{|obj|obj.component_actions()}.flatten
    end


    def add_subtask(hash)
      @elements ||= Array.new
      new_subtask = Task.new(hash.merge(:status => "created"),c)
      @elements << new_subtask
      new_subtask
    end

    def has_error?()
      self[:has_error] 
    end

    def update_status(new_status)
      update({:status => new_status.to_s}) if @id_handle
    end         

    def add_event(msg)
      TaskEvent.add(@id_handle,msg) if @id_handle
    end
    def add_error(error)
      return nil unless @id_handle and error
      TaskError.add(@id_handle,error) 
      self[:has_error] = true
    end

    def add_error_toplevel(error)
      return nil unless @id_handle and error
      return nil if has_error? and error.to_s == ""
      TaskError.add(@id_handle,error)
      self[:has_error] = true 
    end

    
   private
    attr_accessor :elements
  end

  class TaskEvent < Model
    set_relation_name(:task,:event)
    class << self
      def up()
        ##TBD: just using description

        many_to_one :task
      end

      ##### Actions
      def add(task_id_handle,msg)
        create_from_hash(get_factory_id_handle(task_id_handle,:task_event),{:task_event => {:description => msg}})
      end
    end
  end

  class TaskError < Model
    set_relation_name(:task,:error)
    class << self
      def up()
        ##TBD: just using description

        many_to_one :task
      end

      ##### Actions
      def add(task_id_handle,error)
	#TBD: treat more structured errors
        create_from_hash(get_factory_id_handle(task_id_handle,:task_error),{:task_error => {:description => error.to_s}})
      end
    end
  end
end


