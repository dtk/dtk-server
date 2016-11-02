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
  class ObjectLogic::Assembly::Component::Diff::Delete::TaskTemplate
    module SpliceInDeleteAction
      module Mixin
        def splice_in_delete_action!(serialized_content)
          delete_subtask = find_or_add_delete_subtask!(serialized_content)
          add_delete_action_in_subtask!(delete_subtask)
          serialized_content
        end

        private
        # TODO: DTK-2732: if dont convert to using seamntic building blocks to slice in delete subtask then these constants
        #       should refer to constants where workflow is parsed (which should be put in dtk-dsl)
        module ParseTerm
          ACTION_DELIM = '.'
          SUBTASKS = :subtasks
          SUBTASK_ORDER = :subtask_order
          NAME = :name
          NODE = :node
          ACTION = :action
          DSL_LOCATION = :dsl_location
          FLATTEN = :flatten
        end

        def find_or_add_delete_subtask!(serialized_content)
          unless top_subtasks = serialized_content[ParseTerm::SUBTASKS]
            raise_error_unexpecetd_form("Unexpected that term does not have :#{ParseTerm::SUBTASKS} key", serialized_content)
          end
          unless ret = top_subtasks.find { |subtask| subtask[ParseTerm::NAME] ==  delete_subtask_name }
            ret = empty_delete_subtask
            top_subtasks.insert(0, ret)
          end
          ret
        end

        DELETE_SUBTASK_LOCATION = '.workflow/dtk.workflow.delete_subtask_for_create.yaml'
        def empty_delete_subtask
          {
            ParseTerm::NAME          => delete_subtask_name,
            ParseTerm::DSL_LOCATION  => DELETE_SUBTASK_LOCATION,
            ParseTerm::FLATTEN       => true,
            ParseTerm::SUBTASK_ORDER => 'sequential',
            ParseTerm::SUBTASKS      => []
          }
        end

        def add_delete_action_in_subtask!(delete_subtask)
          delete_subtasks = delete_subtask[ParseTerm::SUBTASKS]
          delete_subtasks << delete_action_subtask
          delete_subtasks
        end

        
        def delete_action_subtask
          { 
            ParseTerm::NAME   => "Delete #{component_term}",
            # TODO: DTK-2680: Aldin: explicitly need node name so that this parses; can remove this when extend parsing
            ParseTerm::NODE   => @node.display_name,
            ParseTerm::ACTION => delete_action_term 
          } 
        end

        DELETE_SUBTASK_NAME = 'delete subtask'
        def delete_subtask_name
          DELETE_SUBTASK_NAME
        end

        def component_term
          component_type = Component.component_type_print_form(@component[:component_type])
          title          = @component.title?
          title ? ComponentTitle.print_form_with_title(component_type, title) : component_type
        end

        def delete_action_term
          "#{component_term}#{ParseTerm::ACTION_DELIM}delete"
        end

        def raise_error_unexpecetd_form(err_msg, content)
          fail Error, "#{msg}: #{content.inspect}"
        end

      end
    end
  end
end; end

=begin
{:subtask_order=>"sequential",
 :subtasks=>
  [{:name=>"aws credentials setup",
    :ordered_components=>
     ["identity_aws::credentials",
      "identity_aws::role[na]",
      "network_aws::setup"]},
   {:name=>"aws vpc initialization",
    :ordered_components=>["network_aws::vpc[vpc1]"]},
   {:name=>"aws vpc subnet setup",
    :ordered_components=>["network_aws::vpc_subnet[vpc1-default]"]},
   {:name=>"aws vpc security group setup",
    :actions=>["network_aws::security_group[vpc1-default].delete"]}]}
=end
