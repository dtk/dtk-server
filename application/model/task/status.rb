module DTK
  class Task; module StatusMixin
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def assembly_task_status(assembly_idh,opts={})
        task_mh = assembly_idh.createMH(:task)
        filter = [:eq, :assembly_id, assembly_idh.get_id()]
        unless task = get_top_level_most_recent_task(task_mh,filter)
          assembly = assembly_idh.create_object().update_object!(:display_name)
          raise ErrorUsage.new("No tasks found for assembly (#{assembly[:display_name]})")
        end

        task_structure = get_hierarchical_structure(task_mh.createIDH(:id => task[:id]))

        status_opts = StatusOpts.new
        if status_opts[:detail_level]
          #TODO: stub; treat passed in detail setting status_optss as function of detail_level
          status_opts[:no_components] = false
          status_opts[:no_attributes] = true
        else
          status_opts[:no_components] = false
          status_opts[:no_attributes] = true
        end
        if opts[:format] == :table
          task_structure.status_table_form(status_opts)
        else
          task_structure.status(status_opts)
        end
      end
    end

    def status_table_form(opts,level=1,ndx_errors=nil)
      ret = Array.new
      set_and_return_types!()

      el = hash_subset(:started_at,:ended_at)
      el[:status] = self[:status] unless self[:status] == 'created'
      type = (level == 1 ? :assembly_converge : self[:type])
      #putting idents in
      el[:type] = "#{' '*(2*(level-1))}#{type}"
      ndx_errors ||= self.class.get_ndx_errors(hier_task_idhs())
      if ndx_errors[self[:id]]
        el[:errors] = ndx_errors[self[:id]][:message] #TODO: there is other info we can include
      end

      if level == 1
        #no op
      else
        case self[:executable_action_type]
         when "ConfigNode" 
          if ea = self[:executable_action]
            el.merge!(TaskAction::ConfigNode.status(ea,opts))
          end
         when "CreateNode" 
          if ea = self[:executable_action]
            el.merge!(TaskAction::CreateNode.status(ea,opts))
          end
        end
      end
      ret << el

      num_subtasks = subtasks.size
      #ret.add(self,:temporal_order) if num_subtasks > 1
      if num_subtasks > 0
        ret += subtasks.sort{|a,b| (a[:position]||0) <=> (b[:position]||0)}.map{|st|st.status_table_form(opts,level+1,ndx_errors)}.flatten(1)
      end
      ret
    end

    def status_hash_form(opts,level=1)
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
          subtasks.sort{|a,b| (a[:position]||0) <=> (b[:position]||0)}.map{|st|st.status_hash_form(opts,level+1)}
        end
      end
      case self[:executable_action_type]
       when "ConfigNode" 
        if ea = self[:executable_action]
          ret.merge!(TaskAction::ConfigNode.status(ea,opts))
        end
       when "CreateNode" 
        if ea = self[:executable_action]
          ret.merge!(TaskAction::CreateNode.status(ea,opts))
        end
      end
      errors = get_errors()
      ret[:errors] = errors unless errors.empty?
      ret
    end

    def hier_task_idhs()
      [id_handle()] + subtasks.map{|r|r.hier_task_idhs()}.flatten
    end

    #TODO: probably better to set when creating
    def set_and_return_types!()
      type = nil
      if self[:task_id].nil?
        #TODO: stub that gets changed when different ways to generate tasks
        type = "commit_cfg_changes"
      else
        if action_type = self[:executable_action_type]
          type = ActionTypeCodes[action_type.to_s]
        else
          #assumption that all subtypes some type
          if sample_st = subtasks.first
            if sample_st[:executable_action_type]
              sample_type = ActionTypeCodes[sample_st[:executable_action_type]]
              type = (sample_type && "#{sample_type}s") #make plural
            end
          end 
        end
      end
      subtasks.each{|st|st.set_and_return_types!()}
      self[:type] = type
    end
    protected :set_and_return_types!
    ActionTypeCodes = {
      "ConfigNode" => "configure_node",
      "CreateNode" => "create_node"
    }

    def hier_task_idhs()
      [id_handle()] + subtasks.map{|r|r.hier_task_idhs()}.flatten
    end
    protected :hier_task_idhs

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
    class StatusOpts < Hash
      def initialize(hash_opts={})
        super()
        replace(hash_opts) unless hash_opts.empty?
      end
    end
  end; end
end
