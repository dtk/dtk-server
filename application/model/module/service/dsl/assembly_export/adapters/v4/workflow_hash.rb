module DTK; class ServiceModule  
  class AssemblyExport; class V4 
    module WorkflowHash
      include Task::Template::Serialization
      def self.canonical_form(input_hash)
        ret = input_hash.class.new()
        input_hash.each_pair do |k,info|
          # TODO: assuming that just one level workflow
          ret[k] =
            case k
             when :subtasks
              info.map{|subtask|subtask_canonical_form(subtask)}
             else
              info
            end
        end  
        ret
      end

      def self.subtask_canonical_form(input_hash)
        ret = input_hash.class.new()
        input_hash.each_pair do |k,info|
            # TODO: assuming that just one level workflow
            case k
             when :nodes
              if  Constant.matches?(info,:AllApplicable)
              # remove no op
              else
                ret[k] = info
              end
             else
              ret[k] = info
            end
        end
        ret
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
