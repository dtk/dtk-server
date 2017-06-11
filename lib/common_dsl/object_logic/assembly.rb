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
module DTK
  module CommonDSL
    module ObjectLogic
      class Assembly < ContentInputHash
        require_relative('assembly/diff')

        require_relative('assembly/attribute')
        require_relative('assembly/component_link')
        # attribute must be before component
        # TODO: DTK-2938: remove all files under assembly/node after making sure that logic incorporated elsewhere
        # require_relative('assembly/node')

        require_relative('assembly/component')
        require_relative('assembly/workflow')

        def self.generate_content_input(assembly_instance)
          new.generate_content_input!(assembly_instance)
        end
        
        def generate_content_input!(assembly_instance)
          set_id_handle(assembly_instance)
          set?(:Attributes, Attribute.generate_content_input?(:assembly, (assembly_instance.get_assembly_level_attributes || {})))
          set?(:Components, Component.generate_content_input(assembly_instance))
          set(:Workflows, Workflow.generate_content_input(assembly_instance))
          self
        end

        ### For diffs
        # opts can have keys:
        #  :service_instance
        #  :impacted_files
        def diff?(assembly_parse, qualified_key, opts = {})
          aggregate_diffs?(qualified_key, opts) do |diff_set|
            diff_set.add_diff_set? Attribute, val(:Attributes), assembly_parse.val(:Attributes)
            diff_set.add_diff_set? Component, val(:Components), assembly_parse.val(:Components)
            diff_set.add_diff_set? Workflow, val(:Workflows), assembly_parse.val(:Workflows)
            # TODO: need to add diffs on all subobjects
            # ...
          end
        end

      end
    end
  end
end
