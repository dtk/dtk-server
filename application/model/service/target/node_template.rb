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
  class Service::Target
    # Module for handling node templates in a target service
    module NodeTemplateMixin
      # This method looks at structure in target_service to see the available node templates and returns teh one that matches
      # node_target
      def find_node_template_from_node_target(node_target)
        #TODO: stub
        pp [:debug, 'Service::Target::Image', node_target]
        # TODO: find in target the image associated with node_target; create if needed
        # stub
        Node::Template.null_node_template(target.model_handle)
      end
      def find_node_template_from_node_binding_ruleset(nb_ruleset)
        #       match = CommandAndControl.find_matching_node_binding_rule(get_field?(:rules), target)
        #      match && get_node_template(match[:node_template])

        pp [:find_node_template_from_node_binding_ruleset, self, nb_ruleset]
        nb_ruleset.node_template_from_match_hash?(node_binding_match_hash)
      end

      private

       def node_binding_match_hash
         Log.error("TODO: remove stub")
         { type: 'ec2_image', region: 'us-east-1' }
       end
    end
  end
end
