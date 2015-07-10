module DTK; class Task; class Status
  class StreamForm
    class Element
      def initialize(type, task)
        @type = type
        @task = task
      end
      private :initialize

      def  hash_form
        {
          type: @type,
          started_at: @task.get_field?(:started_at)
        }
      end

      def self.get_task_start_element(top_level_task)
        TaskStart.new(top_level_task)
      end

      def self.get_stage_elements(top_level_task, start_index, end_index)
        Stage.elements(top_level_task, start_index, end_index)
      end

      class TaskStart < self
        def initialize(task)
          super(:task_start, task)
        end

        def hash_form
          pp @task
          task_structure = @task.get_hierarchical_structure()
          leaf_subtasks = task_structure.get_leaf_subtasks()
          Log.info('stub for Status::StreamForm.status')
[].each do |m| #          [:get_all_subtasks,:get_all_subtasks_with_logs].each do |m|
            pp [m, @task.send(m)]
          end
[].each do |m| ##          [:get_associated_nodes,:get_leaf_subtasks,:get_config_agent_type].each do |m|
            pp [m, task_structure.send(m)]
          end

[].each do |m| #[:get_config_agent_type].each do |m|
            leaf_subtasks.each { |t| pp [m, t.send(m)] }
          end

          status_opts = {}.merge(no_components: false, no_attributes: true)
          status_opts.merge!(summarize_node_groups: true)
          t = TableForm.status(task_structure, status_opts)
          pp t
          File.open('/tmp/t5.rb', 'w') { |f| PP.pp(t, f) }
          super()
        end
      end

      class Stage < self
        def initialize(task)
          super(:stage, task)
        end
        def self.elements(top_level_task, _start_stage, _end_stage)
          #TODO: stub
          # top_level_task.get_stages(start_stage,end_stage)
          [new(top_level_task)]
        end
      end
    end
  end
end; end; end
