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
  module CommandAndControlAdapter::Ec2::Reified
    module ConnectedComponentMixin
      private

      def connected_component_aux(conn_cmp_type, reified_target)
        use_and_set_connected_component_cache(conn_cmp_type) { get_connected_component(conn_cmp_type, reified_target) }
      end

      def get_connected_component(component_type, reified_target)
        link_def_type = Target::Component::Type.name(component_type)
        dtk_component_ids = get_connected_dtk_component_ids(link_def_type)
        components = reified_target.matching_components(dtk_component_ids)
        if components.size === 0
          # TODO: change to return violation or trap this to return violation
          fail ErrorUsage, "No matching components for '#{component_type}'"
        elsif components.size > 1
          # TODO: change to return violation or tarp this to return violation
          fail ErrorUsage, "Multiple matching components  for '#{component_type}'"
        end
        components.first
      end

    end
  end
end

