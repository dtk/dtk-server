module DTK
  class Task
    class Status
      r8_nested_require('status', 'type')
      r8_nested_require('status', 'table_form')
      r8_nested_require('status', 'list_form')
      r8_nested_require('status', 'stream_form')

      private

      def self.get_status_aux(ref_obj_idh,ref_obj_type,filter,opts={})
        top_level_task = get_top_level_most_recent_task(ref_obj_idh,ref_obj_type,filter)
        task_structure = Hierarchical.get(top_level_task.id_handle(), reify: true)
        status_opts = Hash.new.merge(no_components: false, no_attributes: true)
        status_opts.merge!(summarize_node_groups: true) if (opts[:detail_level]||{})[:summarize_node_groups]
        case opts[:format]
          when :table
            TableForm.status(task_structure, status_opts)
          when :list
            ListForm.status(task_structure, ref_obj_idh.createMH(:node))
          else
            fail ErrorUsage.new("Unexpected format '#{opts[:format]}'")
        end
      end

      def self.get_top_level_most_recent_task(ref_obj_idh, ref_obj_type, filter)
        task_mh = ref_obj_idh.createMH(:task)
        unless task = Task.get_top_level_most_recent_task(task_mh, filter)
          task_obj = ref_obj_idh.create_object().update_object!(:display_name)
          fail ErrorUsage.new("No tasks found for #{ref_obj_type} (#{task_obj[:display_name]})")
        end
        task
      end

      class Assembly < self
        def self.get_status(assembly_idh, opts = {})
          filter = [:eq, :assembly_id, assembly_idh.get_id()]
          get_status_aux(assembly_idh, :assembly, filter, opts)
        end

        module StreamForm
          def self.get_status(assembly_idh, opts = {})
            filter = [:eq, :assembly_id, assembly_idh.get_id()]
            top_level_task = Status.get_top_level_most_recent_task(assembly_idh, :service_instance, filter)
            Status::StreamForm.status(top_level_task, opts)
          end
        end
      end

      class Node < self
        def self.get_status(node_idh, opts = {})
          filter = [:eq, :node_id, node_idh.get_id()]
          get_status_aux(node_idh, :node, filter, opts)
        end
      end

      class NodeGroup < self
        def self.get_status(node_group_idh, opts = {})
          filter = [:eq, :node_id, node_group_idh.get_id()]
          get_status_aux(node_group_idh, :node_group, filter, opts)
        end
      end

      class Target < self
        def self.get_status(target_idh, opts = {})
          filter = [:eq, :target_id, target_idh.get_id()]
          get_status_aux(target_idh, :target, filter, opts)
        end
      end
    end

    module StatusMixin
      # TODO: move to own file
      def status_hash_form(opts, level = 1)
        set_and_return_types!()
        ret = PrettyPrintHash.new
        if level == 1
          ret.add(self, :type, :id, :status, :commit_message?)
        else
          ret.add(self, :type, :status)
        end
        ret.add(self, :started_at?)
        ret.add(self, :ended_at?)
        num_subtasks = subtasks.size
        ret.add(self, :temporal_order) if num_subtasks > 1
        if num_subtasks > 0
          ret.add(self, :subtasks) do |subtasks|
            subtasks.sort { |a, b| (a[:position] || 0) <=> (b[:position] || 0) }.map { |st| st.status_hash_form(opts, level + 1) }
          end
        end
        case self[:executable_action_type]
        when 'ConfigNode'
          if ea = self[:executable_action]
            ret.merge!(Action::ConfigNode.status(ea, opts))
          end
        when 'CreateNode'
          if ea = self[:executable_action]
            ret.merge!(Action::CreateNode.status(ea, opts))
          end
        end
        errors = get_errors()
        ret[:errors] = errors unless errors.empty?
        ret
      end

      # TODO: probably better to set when creating
      def set_and_return_types!
        type =
          if self[:task_id].nil?
          self[:display_name] || 'commit_cfg_changes'
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
                suffix = /config_node(\w.+)/.match(self[:display_name])[1] if sample_st[:executable_action_type] == 'ConfigNode'
                sample_type && "#{sample_type}s#{suffix}" #make plural
              end
            end
          end

        subtasks.each(&:set_and_return_types!)
        self[:type] = type
      end

      ActionTypeCodes = {
        'ConfigNode' => 'configure_node',
        'CreateNode' => 'create_node'
      }

      # for debugging
      def pretty_print_hash
        ret = PrettyPrintHash.new
        ret.add(self, :id, :status)
        num_subtasks = subtasks.size
        # only include :temporal_order if more than 1 subtask
        ret.add(self, :temporal_order) if num_subtasks > 1
        if num_subtasks > 0
          ret.add(self, :subtasks) do |subtasks|
            subtasks.sort { |a, b| (a[:position] || 0) <=> (b[:position] || 0) }.map(&:pretty_print_hash)
          end
        end
        action_type = self[:executable_action_type]
        case action_type
        when 'ConfigNode'
          ret.add(self, :executable_action_type)
          ret.add(self, :executable_action?) { |ea| Action::ConfigNode.pretty_print_hash(ea) }
        when 'CreateNode'
          ret.add(self, :executable_action_type)
          ret.add(self, :executable_action?) { |ea| Action::CreateNode.pretty_print_hash(ea) }
        else
          ret.add(self, :executable_action_type?, :executable_action?)
        end
        ret
      end
    end
  end
end
