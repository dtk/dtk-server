module DTK
  class Task 
    class Hierarchical < self
      def self.get_and_reify(top_task_idh)
        get(top_task_idh, reify: true)
      end

      def self.get(top_task_idh, opts = {})
        sp_hash = {
          :cols => common_columns(),
          :filter => [:eq, :id, top_task_idh.get_id()]
        }
        top_task = get_objs(top_task_idh.createMH(),sp_hash).first
        return nil unless top_task
        flat_subtask_list = top_task.get_all_subtasks(opts)
        ndx_task_list = {top_task.id => top_task}
        subtask_count = Hash.new
        subtask_indexes = Hash.new
        flat_subtask_list.each do |t|
          ndx_task_list[t.id] = t
          parent_id = t[:task_id]
          subtask_count[parent_id] = (subtask_count[parent_id]||0) +1
          subtask_indexes[t.id] = {:parent_id => parent_id,:index => t[:position]}
        end
        
        subtask_qualified_indexes = QualifiedIndex.compute!(subtask_indexes,top_task)
        
        flat_subtask_list.each do |subtask|
          subtask[QualifiedIndex::Field] = subtask_qualified_indexes[subtask[:id]][QualifiedIndex::Field]
          parent_id = subtask[:task_id]
          parent = ndx_task_list[parent_id]
          if subtask.node_group_member?()
            subtask.set_node_group_member_executable_action!(parent)
          end
          (parent[:subtasks] ||= Array.new(subtask_count[parent_id]))[subtask[:position]-1] = subtask
        end
        top_task
      end

      module Mixin
        ########### get methods ###########

        # indexed by task ids
        def get_ndx_errors
          self.class.get_ndx_errors(hierarchical_task_idhs())
        end
        
        def get_associated_nodes
        ndx_nodes = Hash.new
          get_leaf_subtasks().each do |subtask|
            if node = (subtask[:executable_action]||{})[:node]
              ndx_nodes[node.id()] ||= node
            end
          end
          ndx_nodes.values
        end
        
        def get_leaf_subtasks
          if subtasks = subtasks?
            subtasks.inject(Array.new){|a,st|a+st.get_leaf_subtasks()}
          else
            [self]
          end
        end

        # recursively walks structure, but returns them in flat list
        def get_all_subtasks(opts={})
          self.class.get_all_subtasks([id_handle()],opts)
        end
        ########### end: get methods ###########

        ########### update methods ###########
        def update_task_subtask_status(status, result)
          subtasks.each do |subtask|
            if subtask[:subtasks]
              subtask[:subtasks].each do |child_subtask|
                child_subtask.update_at_task_completion(status, result)
              end
            end
            subtask.update_at_task_completion(status, result)
          end
          self.update_at_task_completion(status, result)
        end

        # TODO: update and update_parents can be cleaned up because halfway between update and update_object!
        # this updates self, which is leaf node, plus all parents
        def update(update_hash, opts = {})
          super(update_hash)
          unless opts[:dont_update_parents] || (update_hash.keys & [:status, :started_at, :ended_at]).empty?
            if task_id = update_object!(:task_id)[:task_id]
              update_parents(update_hash.merge(task_id: task_id))
            end
          end
        end
        
        # updates parent fields that are fn of children (:status,:started_at,:ended_at)
        def update_parents(child_hash)
          parent = id_handle.createIDH(id: child_hash[:task_id]).create_object().update_object!(:status, :started_at, :ended_at, :children_status)
          key = id().to_s.to_sym #TODO: look at avoiding this by having translation of json not make num keys into symbols
          children_status = (parent[:children_status] || {}).merge!(key => child_hash[:status])
          
          parent_updates = { children_status: children_status }
          # compute parent start time
          unless parent[:started_at] || child_hash[:started_at].nil?
            parent_updates.merge!(started_at: child_hash[:started_at])
          end
          
          # compute new parent status
          subtask_status_array = children_status.values
          parent_status =
            if subtask_status_array.include?('executing') then 'executing'
            elsif subtask_status_array.include?('failed') then 'failed'
            elsif subtask_status_array.include?('cancelled') then 'cancelled'
            elsif not subtask_status_array.find { |s| s != 'succeeded' } then 'succeeded' #all succeeded
            else 'executing' #if reach here must be some created and some finished
            end
          unless parent_status == parent[:status]
            parent_updates.merge!(status: parent_status)
            # compute parent end time which can only change if parent changed to "failed" or "succeeded"
            if ['failed', 'succeeded'].include?(parent_status) && child_hash[:ended_at]
              parent_updates.merge!(ended_at: child_hash[:ended_at])
            end
          end
          
          dont_update_parents = (parent_updates.keys - [:children_status]).empty?
          parent.update(parent_updates, dont_update_parents: dont_update_parents)
        end
        private :update_parents

        ########### end: update methods ###########

        ########### db persistence methods ###########
        # saves hirerachical structure to db and returns task with top level and subtask ids filled out
        def save_and_add_ids
          save!()
          # TODO: this is simple but expensive way to get all teh embedded task ids filled out
          # can replace with targeted method that does just this
          Hierarchical.get_and_reify(id_handle())
        end
        
        # persists to db this and its sub tasks
        def save!
          # no op if saved already as detected by whether has an id
          return nil if id()
          set_positions!()
          # for db access efficiency implement into two phases: 1 - save all subtasks w/o ids, then put in ids
          unrolled_tasks = unroll_tasks()
          rows = unrolled_tasks.map do |hash_row|
            executable_action = hash_row[:executable_action]
            row = {
              display_name: hash_row[:display_name] || "task#{hash_row[:position]}",
              ref: "task#{hash_row[:position]}",
              executable_action_type: executable_action ? Aux.demodulize(executable_action.class.to_s) : nil,
              executable_action: executable_action
            }
            cols = [:status, :result, :action_on_failure, :position, :temporal_order, :commit_message]
            cols.each { |col| row.merge!(col => hash_row[col]) }
            [:assembly_id, :node_id, :target_id].each do |col|
              row[col] = hash_row[col] || SQL::ColRef.null_id
            end
            row
          end
          new_idhs = Model.create_from_rows(model_handle, rows, convert: true, do_not_update_info_table: true)
          unrolled_tasks.each_with_index { |task, i| task.set_id_handle(new_idhs[i]) }
          
          # set parent relationship and use to set task_id (subtask parent) and children_status
          par_rel_rows_for_id_info = set_and_ret_parents_and_children_status!()
          par_rel_rows_for_task = par_rel_rows_for_id_info.map { |r| { id: r[:id], task_id: r[:parent_id], children_status: r[:children_status] } }
          
          Model.update_from_rows(model_handle, par_rel_rows_for_task) unless par_rel_rows_for_task.empty?
          IDInfoTable.update_instances(model_handle, par_rel_rows_for_id_info)
        end
        ########### end: db persistence methods ###########

        ########### add and set methods ###########
        def add_subtask_from_hash(hash)
          defaults = { status: 'created', action_on_failure: 'abort' }
          new_subtask = Task.new(defaults.merge(hash), c)
          add_subtask(new_subtask)
        end
        
        def add_subtask(new_subtask)
          (self[:subtasks] ||= []) << new_subtask
          new_subtask
        end

        def add_subtasks(new_subtasks)
          new_subtasks.each { |new_subtask| (self[:subtasks] ||= []) << new_subtask }
          self
        end
        
        def set_positions!
          self[:position] ||= 1
          return nil if subtasks.empty?
          subtasks.each_with_index do |e, i|
            e[:position] = i + 1
            e.set_positions!()
          end
        end

        def set_and_ret_parents_and_children_status!(parent_id = nil)
          self[:task_id] = parent_id
          id = id()
          if subtasks.empty?
            [parent_id: parent_id, id: id, children_status: nil]
          else
            recursive_subtasks = subtasks.map { |st| st.set_and_ret_parents_and_children_status!(id) }.flatten
            children_status = subtasks.inject({}) { |h, st| h.merge(st.id() => 'created') }
            [parent_id: parent_id, id: id, children_status: children_status] + recursive_subtasks
          end
        end
        
        
        ########### end: add and set methods ###########

        def is_status?(status)
          self[:status] == status || subtasks.find{ |subtask| subtask[:status] == status }
        end

        def component_actions
          if executable_action().is_a?(Action::ConfigNode)
            action = executable_action()
            action.component_actions().map { |ca| action[:node] ? ca.merge(node: action[:node]) : ca }
          else
            subtasks.map(&:component_actions).flatten
          end
        end
        
        def node_level_actions
          if executable_action().is_a?(Action::NodeLevel)
            action = executable_action()
            return action.component_actions().map { |ca| action[:node] ? ca.merge(node: action[:node]) : ca }
          else
            subtasks.map(&:node_level_actions).flatten
          end
        end
        
        def unroll_tasks
          [self] + subtasks.map(&:unroll_tasks).flatten
        end
        
        def subtasks
          self[:subtasks] || []
        end

        def subtasks?
          self[:subtasks]
        end

        def render_form
          # may be different forms; this is one that is organized by node_group, node, component, attribute
          task_list = render_form_flat(true)
          # TODO: not yet teating node_group
          Task.render_group_by_node(task_list)
        end

        protected

        def render_form_flat(top = false)
          # prune out all (sub)tasks except for top and  executable
          return render_executable_tasks() if executable_action(no_error_if_nil: true)
          (top ? [render_top_task()] : []) + subtasks.map(&:render_form_flat).flatten
        end
        
        def hierarchical_task_idhs
          [id_handle()] + subtasks.map{|r|r.hierarchical_task_idhs()}.flatten
        end

      end
    end
  end
end
