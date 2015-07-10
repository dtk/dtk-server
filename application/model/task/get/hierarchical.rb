# These methods apply to case where self or passed task argument are hierarchical tasks
module DTK; class Task
  module Get
    module HierarchicalMixin
      def get_errors
        sp_hash = {
          :cols => [:content]
        }
        get_children_objs(:task_error,sp_hash).map{|r|r[:content]}
      end

      # indexed by task ids
      def get_ndx_errors
        self.class.get_ndx_errors(hier_task_idhs())
      end
    
      def get_logs
        ret = Hash.new
        sp_hash = {:cols => [:task_id, :display_name, :content, :parent_task]}
        rows = get_children_objs(:task_log, sp_hash).sort{|a,b| a[:created_at] <=> b[:created_at]}
        
        rows.each do |r|
          task_id = r[:task_id]
          content = r[:content] || Hash.new
          content.merge!({:label => r[:display_name], :task_name => r[:task][:display_name]})
          ret[task_id] = (ret[task_id]||Array.new) + [content]
        end

        ret
      end

      def get_ndx_logs
        self.class.get_ndx_logs(hier_task_idhs())
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

      def get_hierarchical_structure
      self.class.get_hierarchical_structure(id_handle())
      end
      
      # recursively walks structure, but returns them in flat list
      def get_all_subtasks(opts={})
        self.class.get_all_subtasks([id_handle()],opts)
      end
    end

    module HierarchicalClassMixin
      def get_hierarchical_structure(top_task_idh)
        sp_hash = {
          :cols => Task.common_columns(),
          :filter => [:eq, :id, top_task_idh.get_id()]
        }
        top_task = get_objs(top_task_idh.createMH(),sp_hash).first
        return nil unless top_task
        flat_subtask_list = top_task.get_all_subtasks()
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

      def get_all_subtasks(top_id_handles,opts={})
        ret = Array.new
        id_handles = top_id_handles
        until id_handles.empty?
          model_handle = id_handles.first.createMH()
          sp_hash = {
            :cols => opts[:cols] || Task.common_columns(), 
            :filter => [:oneof, :task_id, id_handles.map{|idh|idh.get_id}]
          }
          next_level_objs = get_objs(model_handle,sp_hash).reject{|k,v|k == :subtasks}
          next_level_objs.each{|st|st.reify!()}
          id_handles = next_level_objs.map{|obj|obj.id_handle}
          
          ret += next_level_objs
        end
        ret
      end

    end
  end
end; end


