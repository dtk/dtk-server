module DTK
  class Task 
    class Status
      r8_nested_require('status','table_form')
      r8_nested_require('status','list_form')

      def self.get_active_top_level_tasks(model_handle)
        # TODO: need protection so dont get stake tasks that never came out of executing mode
        filter = [:and, [:eq,:status,"executing"],[:or,[:neq,:assembly_id,nil],[:neq,:node_id,nil]]]
        Task.get_top_level_tasks(model_handle,filter)
      end

      def self.find_nodes_that_are_active(model_handle)
        ret = Array.new
        model_handle = model_handle.createMH(:task)
        top_level_active = get_active_top_level_tasks(model_handle)
        return ret if top_level_active.empty?
        # TODO: way to make call Task.get_all_subtasks faster 
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
        status_opts = Opts.new(:no_components=>false,:no_attributes=>true)
        status_opts.merge!(:summarize_node_groups => true) if (opts[:detail_level]||{})[:summarize_node_groups]
        case opts[:format]
          when :table
            TableForm.status(task_structure,status_opts)
          when :list
            ListForm.status(task_structure,task_obj_idh.createMH(:node))
          else
            task_structure.status(status_opts)
        end
      end

      def self.get_action_detail_aux(task_obj_idh, task_obj_type, filter, message_id, opts={})
        log, ret = [], ""
        task_mh = task_obj_idh.createMH(:task)

        unless task = Task.get_top_level_most_recent_task(task_mh,filter)
          task_obj = task_obj_idh.create_object().update_object!(:display_name)
          raise ErrorUsage.new("No tasks found for #{task_obj_type} (#{task_obj[:display_name]})")
        end

        subtasks = task.get_all_subtasks_with_logs()
        task_log_mh = task_obj_idh.createMH(:task_log)
        subtasks.each do |sub|
          sp_hash = {
            :cols => [:id, :display_name, :content],
            :filter => [:and, [:eq, :display_name, message_id], [:eq, :task_id, sub[:id]]],
            # :order_by => [{:field => :id, :order => "ASC"}]
            :order_by => [{:field => :id, :order => "DESC"}]
          }
          log = Model.get_objs(task_log_mh,sp_hash)
          break unless log.empty?
        end

        raise ErrorUsage.new("Task action with identifier '#{message_id}' does not exist for this service instance.") if log.empty?

        if log.size > 1
          log.each do |l|
            content = l[:content]
            ret << "==============================================================\n"
            ret << "RUN: #{content[:description]} \n"
            ret << "STATUS: #{content[:status]} \n"
            ret << "STDOUT: #{content[:stdout]}\n\n" if content[:stdout] && !content[:stdout].empty?
            ret << "STDERR: #{content[:stderr]} \n" if content[:stderr] && !content[:stderr].empty?
          end
        else
          log     = log.first
          content = log[:content]

          return unless content

          ret << "RUN: #{content[:description]} \n"
          ret << "STATUS: #{content[:status]} \n"
          ret << "STDOUT: #{content[:stdout]}\n\n" if content[:stdout] && !content[:stdout].empty?
          ret << "STDERR: #{content[:stderr]} \n" if content[:stderr] && !content[:stderr].empty?
        end

        ret
      end

      class Assembly < self
        def self.get_active_nodes(model_handle)
          find_nodes_that_are_active(model_handle)
        end

        def self.get_status(assembly_idh,opts={})
          filter = [:eq, :assembly_id, assembly_idh.get_id()]
          get_status_aux(assembly_idh,:assembly,filter,opts)
        end

        def self.get_action_detail(assembly_idh, message_id, opts={})
          filter = [:eq, :assembly_id, assembly_idh.get_id()]
          get_action_detail_aux(assembly_idh, :assembly, filter, message_id, opts)
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

      class Target < self
        def self.get_status(target_idh, opts={})
          filter = [:eq, :target_id, target_idh.get_id()]
          get_status_aux(target_idh, :target, filter, opts)
        end
      end

      class Opts < Hash
        def initialize(hash_opts={})
          super()
          replace(hash_opts) unless hash_opts.empty?
        end
      end
    end
   
    module StatusMixin
    # TODO: move to own file
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
      
      # TODO: probably better to set when creating
      def set_and_return_types!()
        type = 
          if self[:task_id].nil?
          self[:display_name]||"commit_cfg_changes"
          elsif action_type = self[:executable_action_type]
            ActionTypeCodes[action_type.to_s]
          elsif self[:display_name]
            self[:display_name]
          else
            # TODO: probably deprecate below; it at least needs fixing up
            # assumption that all subtypes some type
            if sample_st = subtasks.first
              if sample_st[:executable_action_type]
                sample_type = ActionTypeCodes[sample_st[:executable_action_type]]
                suffix = /config_node(\w.+)/.match(self[:display_name])[1] if sample_st[:executable_action_type] == "ConfigNode"
                sample_type && "#{sample_type}s#{suffix}" #make plural
              end
            end 
          end
        
        subtasks.each{|st|st.set_and_return_types!()}
        self[:type] = type
      end

      ActionTypeCodes = {
        "ConfigNode" => "configure_node",
        "CreateNode" => "create_node"
      }

      def hier_task_idhs()
        [id_handle()] + subtasks.map{|r|r.hier_task_idhs()}.flatten
      end
      protected :hier_task_idhs

      # for debugging
      def pretty_print_hash()
        ret = PrettyPrintHash.new
        ret.add(self,:id,:status)
        num_subtasks = subtasks.size
        # only include :temporal_order if more than 1 subtask
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
    end
  end
end
