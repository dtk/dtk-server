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
module DTK; class Task; class Template; class Stage
  class InterNode
    # TODO: DTK-2680: Aldin: New subclass of InterNode to treat nested subtasks
    #     This has to be expanded to treat serialized_content which can gave form
    # 
    class NestedSubtask < self
      def initialize(serialized_content)
        pp ['nested subtask serialized_content', serialized_content] 
        # Here is example 
        # {:name=>"delete subtask",
        # :dsl_location=>".workflow/dtk.workflow.delete_subtask_for_create.yaml",
        # :flatten=>true,
        # :subtask_order=>"sequential",
        # :subtasks=>
        # [{:name=>"Delete network_aws::vpc_subnet[vpc1-default]",
        #    :node=>"assembly_wide",
        #    :action=>"network_aws::vpc_subnet[vpc1-default].delete"}]}]
        # case above has one element under subtasks; this can have multiple ones
        super(serialized_content[:name])
        @subtasks = []
      end

      def serialization_form(opts = {})
        # TODO: put in other fields needed by serialization form; this is all above except 
        #  think flatten and dsl_location; pr might be that dependening on opts we omit these fields 
        # dependening on whether this is saved in database contentr field of task template (where we want it vesus used to produce hash
        # which is writtemn to dsl wheer it is omitted
        # TODO: stub
        @subtasks.first.serialization_form(opts)
      end

      def find_earliest_match?
        # TODO: stub
        # TODO: DTK-2680: Aldin: this was changed to get around error where internode_stage is an array
        #       put in logic where not searching for action inside of nested subtask; need to see if this is right
        nil
      end

      # opts can have keys:
      #  :just_parse (Boolean)
      def self.parse_and_reify(serialized_content, action_list, opts = {})
        new(serialized_content).parse_and_reify!(serialized_content, action_list, opts)
      end
      def parse_and_reify!(serialized_content, action_list, opts = {})
        unless subtasks = serialized_content[Field::Subtasks]
          fail Error, "Unexepcetd that serialized_content[Field::Subtasks] is nil"
        end
        subtasks.each do |subtask|
          @subtasks << self.class.parse_and_ret_normalized_content([subtask], serialized_content, action_list, opts)
        end
        self
      end

    end
  end
end; end; end; end
