module DTK
  class Task; module StatusMixin
    class Status
      def self.get_active_top_level_tasks(model_handle)
        #TODO: need protection so dont get stake tasks that never came out of executing mode
        filter = [:and, [:eq,:status,"executing"],[:or,[:neq,:assembly_id,nil],[:neq,:node_id,nil]]]
        Task.get_top_level_tasks(model_handle,filter)
      end

      def self.find_nodes_that_are_active(model_handle)
        ret = Array.new
        model_handle = model_handle.createMH(:task)
        top_level_active = get_active_top_level_tasks(model_handle)
        return ret if top_level_active.empty?
        #TODO: way to make call Task.get_all_subtasks faster 
        ndx_ret = Hash.new
        Task.get_all_subtasks(top_level_active.map{|t|t.id_handle}).each do |sub_task|
          if node = (sub_task[:executable_action] && sub_task[:executable_action][:node])
            ndx_ret[node[:id]] ||= node
          end
        end
        ndx_ret.values
      end

     private
      def self.get_status_aux(task_obj_idh,task_obj_type,filter,opts={})
        task_mh = task_obj_idh.createMH(:task)

        unless task = Task.get_top_level_most_recent_task(task_mh,filter)
          task_obj = task_obj_idh.create_object().update_object!(:display_name)
          raise ErrorUsage.new("No tasks found for #{task_obj_type} (#{task_obj[:display_name]})")
        end

        task_structure = Task.get_hierarchical_structure(task_mh.createIDH(:id => task[:id]))
        
        status_opts = Opts.new
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
      class Assembly < self
        def self.get_active_nodes(model_handle)
          find_nodes_that_are_active(model_handle)
        end

        def self.get_status(assembly_idh,opts={})
          filter = [:eq, :assembly_id, assembly_idh.get_id()]
          get_status_aux(assembly_idh,:assembly,filter,opts)
        end
      end

      class Node < self
        def self.get_status(node_idh,opts={})
          filter = [:eq, :node_id, node_idh.get_id()]
          get_status_aux(node_idh,:node,filter,opts)
        end
      end

      class NodeGroup < self
        def self.get_status(node_group_idh,opts={})
          filter = [:eq, :node_id, node_group_idh.get_id()]
          get_status_aux(node_group_idh,:node_group,filter,opts)
        end
      end

      class Opts < Hash
        def initialize(hash_opts={})
          super()
          replace(hash_opts) unless hash_opts.empty?
        end
      end
    end

    def status_table_form(opts,level=1,ndx_errors=nil)
      ret = Array.new
      set_and_return_types!()

      el = hash_subset(:started_at,:ended_at)
      el[:status] = self[:status] unless self[:status] == 'created'
      type = (level == 1 ? self[:display_name] : self[:type])|| "top"
      #putting idents in
      el[:type] = "#{' '*(2*(level-1))}#{type}"
      ndx_errors ||= self.class.get_ndx_errors(hier_task_idhs())
      if ndx_errors[self[:id]]
        el[:errors] = status_table_form_format_errors(ndx_errors[self[:id]])
      end

      if level == 1
        #no op
      else
        case self[:executable_action_type]
         when "ConfigNode" 
          if ea = self[:executable_action]
            el.merge!(Action::ConfigNode.status(ea,opts))
          end
         when "CreateNode" 
          if ea = self[:executable_action]
            el.merge!(Action::CreateNode.status(ea,opts))
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


    def status_table_form_format_errors(errors)
      ret = nil
      errors.each do |error|
        if ret
          ret[:message] << "\n\n"
        else
          ret = {:message => String.new}
        end

        error_msg = (error[:component] ? "Component #{error[:component].gsub("__","::")}: " : "")
        error_msg << (error[:message]||"error")
        ret[:message] << error_msg
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
          ret.merge!(Action::ConfigNode.status(ea,opts))
        end
       when "CreateNode" 
        if ea = self[:executable_action]
          ret.merge!(Action::CreateNode.status(ea,opts))
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
              suffix = /config_node(\w.+)/.match(self[:display_name])[1] if sample_st[:executable_action_type] == "ConfigNode"
              type = (sample_type && "#{sample_type}s#{suffix}") #make plural
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
        ret.add(self,:executable_action?){|ea|Action::ConfigNode.pretty_print_hash(ea)}
       when "CreateNode" 
        ret.add(self,:executable_action_type)
        ret.add(self,:executable_action?){|ea|Action::CreateNode.pretty_print_hash(ea)}
       else
        ret.add(self,:executable_action_type?,:executable_action?)
      end
      ret
    end
  end; end
end
