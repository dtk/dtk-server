module DTK; class Task
  module RenderMixin
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def assembly_task_status(assembly_idh,detail_level=nil)
        task_mh = assembly_idh.createMH(:task)
        filter = [:eq, :assembly_id, assembly_idh.get_id()]
        unless task = get_top_level_most_recent_task(task_mh,filter)
          assembly = assembly_idh.create_object().update_object!(:display_name)
          raise ErrorUsage.new("No tasks found for assembly (#{assembly[:display_name]})")
        end

        task_structure = get_hierarchical_structure(task_mh.createIDH(:id => task[:id]))

        opts = StateInfoOpts.new
        if detail_level
          #TODO: stub; treat passed in detail setting Task::StateInfoOpts as function of detail_level
          opts[:no_components] = false
          opts[:no_attributes] = true
        else
          opts[:no_components] = false
          opts[:no_attributes] = true
        end
        task_structure.state_info(opts)
      end
    end

    #TODO: may change method name to 'status'
    def state_info(opts,level=1)
      set_and_return_types!()
      ret = PrettyPrintHash.new
      if level == 1
        ret.add(self,:type,:id,:status,:commit_message?)
      else
        ret.add(self,:type,:status)
      end
      ret.add(self,:started_at?)
      ret.add(self,:ended_at?)
      num_subtasks = subtasks.size
      ret.add(self,:temporal_order) if num_subtasks > 1
      if num_subtasks > 0
        ret.add(self,:subtasks) do |subtasks|
          subtasks.sort{|a,b| (a[:position]||0) <=> (b[:position]||0)}.map{|st|st.state_info(opts,level+1)}
        end
      end
      action_type = self[:executable_action_type]
      case action_type
       when "ConfigNode" 
        if ea = self[:executable_action]
          ret.merge!(TaskAction::ConfigNode.state_info(ea,opts))
        end
       when "CreateNode" 
        if ea = self[:executable_action]
          ret.merge!(TaskAction::CreateNode.state_info(ea,opts))
        end
      end
      add_task_errors!(ret,opts)
      ret
    end

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
  end
end; end
