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
    module NodeTemplate
      # This method looks at structure in target_service to see the available node templates and returns teh one that matches
      # node_target
      def find_matching_node_template(node_target)
        #TODO: stub
        pp [:debug, 'Service::Target::Image', node_target]
        # TODO: find in target the image associated with node_target; create if needed
        # stub
        Node::Template.null_node_template(target.model_handle)
      end
    end
  end
end
