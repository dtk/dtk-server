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
module DTK; class Assembly::Instance
  module Describe
    module Actions
      def self.describe(service_instance, params, opts = {})
        assembly_instance = service_instance.copy_as_assembly_instance
        dsl_version       = service_instance.get_service_instance_branch.dsl_version

        if opts['show_steps']
          task_opts = {
            start_nodes: false,
            ret_nodes_to_start: []
          }
          if task_action = (params || []).first
            task_opts.merge!(task_action: task_action)
          end
          task = Task.create_from_assembly_instance?(service_instance, task_opts)
          task_status = nil

          # this is workaround to display exact same workflow as if it was executed with service exec
          # get_status depends on task ids from the database to properly calculate task status table
          # will substitute this with generating task_status without saving to database when figure out
          # how to calculate task status with fake ids instead of those from the database
          begin
            Model.Transaction do
              task.save!()
              task_status = Task::Status::Assembly.get_status(service_instance.id_handle, format: :table, top_level_task: task)
              raise DescribeActionRollback
            end
          rescue DescribeActionRollback => e
          end
        
          return task_status
        else
          # using params.first for action name because currently we only have one level for actions
          actions_content_input = CommonDSL::ObjectLogic::Assembly::Workflow.generate_content_input(assembly_instance, (params || []).first )
          top_level_content_input  = CommonDSL::ObjectLogic::ContentInputHash.new('actions' => actions_content_input)

          yaml_content = CommonDSL::Generate::FileGenerator.generate_yaml_text(:workflow, top_level_content_input, dsl_version)
          hash_content = YAML.load(yaml_content)

          hash_content['actions'] || {}
        end
      end

      class DescribeActionRollback < StandardError
      end
    end
  end
end; end
