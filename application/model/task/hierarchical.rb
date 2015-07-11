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
          if subtasks = self[:subtasks]
            subtasks.inject(Array.new){|a,st|a+st.get_leaf_subtasks()}
          else
            [self]
          end
        end

        # recursively walks structure, but returns them in flat list
        def get_all_subtasks(opts={})
          self.class.get_all_subtasks([id_handle()],opts)
        end

        protected

        def hierarchical_task_idhs
          [id_handle()] + subtasks.map{|r|r.hierarchical_task_idhs()}.flatten
        end

      end
    end
  end
end
