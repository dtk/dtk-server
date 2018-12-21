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
module DTK; class Clone
  class IncrementalUpdate
    class ComponentLinks < self
      
      private

      # TODO: put in equality test so that does not need to do the modify equal objects
      def equal_so_dont_modify?(_instance, _template)
        false
      end

      def get_ndx_objects(linkdef_idhs)
        ret = {}
        ::DTK::Component.get_component_links_links(linkdef_idhs, cols_plus: [:link_def_id, :ref]).each do |r|
          (ret[r[:link_def_id]] ||= []) << r
        end
        ret
      end
    end
  end
end; end
