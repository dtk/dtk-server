module XYZ
  class Task < Model
    set_relation_name(:task,:task)
    class << self
      def up()
        column :status, :varchar, :size => 20, :default => "in_progres"

        many_to_one :task 
        one_to_many :task, :task_event, :task_error
      end

      ##### Actions
      def create(c=nil) #c == nil means "no task"
	return Task.new(nil,nil) if c.nil?
	uri = create_from_hash(IDHandle[:c => c, :uri => "/task"],{:task => {}}).first
	Task.new(c,uri)	
      end  
    end

    #Instance methods
    def initialize(c,task_uri)
      super({:c => c, :uri => task_uri},c,:task)
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


