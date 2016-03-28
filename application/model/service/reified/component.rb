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
  module Service::Reified
    # Reified::Component is an abstract class that roots classes that reify a set of related service components 
    class Component
      # returns array with same length as names with values for each name it finds
      def get_attribute_values(names, service_component)
        av_pairs = service_component.get_attributes.inject({}) { |h, attr| h.merge(attr.name => attr.value) }
        names.map { |name| av_pairs[name] }
      end

      def get_dtk_attributes(names, service_component)
        ndx_attrs = service_component.get_attributes.inject({}) { |h, attr| h.merge(attr.name => attr) }
        names.map { |name| ndx_attrs[name] && ndx_attrs[name].dtk_attribute }
      end
    end
  end
end
