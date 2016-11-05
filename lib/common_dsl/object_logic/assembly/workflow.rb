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
module DTK; module CommonDSL
  module ObjectLogic
    class Assembly
      class Workflow < ContentInputHash
        require_relative('workflow/diff')
        require_relative('workflow/content')

        def initialize(workflow)
          super()
          @workflow = workflow
        end
        
        def self.generate_content_input(assembly_instance)
          #  Generates a create workflow if one not explicitly given in dsl which causes this to be written to dsl
          Task::Template::ConfigComponents.get_or_generate_template_content(:assembly, assembly_instance)
          workflows = assembly_instance.get_task_templates(set_display_names: true)
          unsorted = workflows.inject({}) do |h, workflow| 
            h.merge(workflow.display_name => new(workflow).generate_content_input!)
          end
          sorted_workflow_names(unsorted.keys).inject(ContentInputHash.new) { |h, workflow_name| h.merge(workflow_name => unsorted[workflow_name]) }
        end

        def generate_content_input!
          set_id_handle(@workflow)
          merge!(Content.generate_content_input(@workflow[:content]))
        end
        
        ### For diffs
        # opts can have keys
        #   :service_instance
        def diff?(workflow_parse, qualified_key, opts = {})
          create_diff?(self, workflow_parse, qualified_key, opts)
        end
        
        # opts can have keys:
        #   :service_instance
        def self.diff_set(workflows_gen, workflows_parse, qualified_key, opts = {})
          diff_set_from_hashes(workflows_gen, workflows_parse, qualified_key, opts)
        end
        
        private
        
        # returns task_template_content associated with create workflow after creating if if needed
        def self.generate_and_persist_create_workflow_if_needed(assembly_instance)
          Task::Template::ConfigComponents.get_or_generate_template_content(:assembly, assembly_instance)
        end

        # alphabetical with create and delete first
        ORDERED_WORKFLOW_NAMES = ['create', 'delete'] 
        def self.sorted_workflow_names(workflow_names)
          ret = []
          names = workflow_names.clone
          ORDERED_WORKFLOW_NAMES.each do |name|
            ret << name if names.delete(name)
          end
          ret + names.sort
        end
        
      end
    end
  end
end; end
