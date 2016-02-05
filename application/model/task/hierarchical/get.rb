#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class Task
  class Hierarchical
    module GetClassMixin
      def get_and_reify(top_task_idh)
        get(top_task_idh, reify: true)
      end

      def get(top_task_idh, opts = {})
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
    end
  end

  module HierarchicalMixin
    module GetMixin
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
        ndx_nodes.values.reject { |node| node.is_assembly_wide_node? }
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

    end
  end
end; end