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
      class Workflow < Generate::ContentInput::Hash
        def initialize(workflow)
          super()
          @workflow = workflow
        end
        private :initialize

        def self.generate_content_input(assembly_instance)
          generate_and_persist_create_workflow_if_needed(assembly_instance)

          workflows = assembly_instance.get_task_templates(set_display_names: true)
          unsorted = workflows.inject({}) do |h, workflow| 
            h.merge(workflow.display_name => new(workflow).generate_content_input!)
          end
          sorted_workflow_names(unsorted.keys).inject(new_input_hash) { |h, workflow_name| h.merge(workflow_name => unsorted[workflow_name]) }
        end

        def generate_content_input!
          change_symbols_to_strings(new_input_hash(@workflow[:content]))
        end

        private
        def self.generate_and_persist_create_workflow_if_needed(assembly_instance)
          Task::Template::ConfigComponents.get_or_generate_template_content(:assembly, assembly_instance)
          nil
        end

        def change_symbols_to_strings(obj)
          if obj.kind_of?(::Hash)
            obj.inject({}) { |h, (k, v)| h.merge(k.to_s => change_symbols_to_strings(v)) }
          elsif obj.kind_of?(::Array)
            obj.map { |el| change_symbols_to_strings(el) }
          elsif obj.kind_of?(::Symbol)
            obj.to_s
          else
            obj
          end
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
            
        def self.new_input_hash(hash = nil)
          hash ? ObjectLogic.new_content_input_hash.merge(hash) : ObjectLogic.new_content_input_hash
        end
        def new_input_hash(hash = nil)
          self.class.new_input_hash(hash)
        end
      end
    end
  end
end; end
