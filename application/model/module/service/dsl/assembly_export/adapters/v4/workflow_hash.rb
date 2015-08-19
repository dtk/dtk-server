module DTK; class ServiceModule
  class AssemblyExport; class V4
    module WorkflowHash
      include Task::Template::Serialization
      
      def self.workflow_hash(input_hash_task_templates)
        input_hash_task_templates.inject(SimpleOrderedHash.new) do |h, (internal_task_action_name, input_hash)|
          task_action_name = Task::Template.task_action_external_name(internal_task_action_name)
          task_body = task_body(input_hash[:content])
          h.merge(task_action_name => task_body)
        end
      end

      private

      # TODO: in methods below assuming that just one level workflow

      def self.task_body(input_hash)
        input_hash.inject(input_hash.class.new) do |h, (k, input_info)|
          info =  
            case k
              when :subtasks
                input_info.map { |input_subtask| subtask(input_subtask) }
              when :assembly_action
                # no op
                nil
              else
              input_info
            end
          info ? h.merge(k => info) : h
        end
      end

      def self.subtask(input_hash)
        input_hash.inject(input_hash.class.new) do |h, (k, input_info)|
          if k == :nodes and Constant.matches?(input_info, :AllApplicable)
            h # omit input_info
          else
            h.merge(k => input_info)
          end
        end
      end

    end
  end; end
end; end

# form to normalize returned by workflow_hash supper
# {:assembly_action=>"create",
#  :subtask_order=>:sequential,
#  :subtasks=>
#   [{:name=>"create component",
#     :node=>"node",
#     :ordered_components=>
#      ["java", "bigtop_toolchain::gradle", "action_module"]},
#    {:name=>"invoke bash test1",
# input_hash)    :nodes=>"All_applicable",
#     :ordered_components=>["action_module.bash_test1"]},
#    {:name=>"invoke rspec test1",
#     :nodes=>"All_applicable",
#     :ordered_components=>["action_module.rspec_test1"]},
#    {:name=>"invoke gradle test1",
#     :nodes=>"All_applicable",
#     :ordered_components=>["action_module.gradle_test1"]}]}
