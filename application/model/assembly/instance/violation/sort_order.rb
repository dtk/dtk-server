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
module DTK; class Assembly::Instance
  class Violation
    module SortOrderClassMixin
      def compare_for_sort(viol1, viol2)
        if viol1.class.impacted_by.include?(viol2.class)
          1 # want viol1 to be after viol2
        elsif viol2.class.impacted_by.include?(viol1.class)
          -1 # want viol2 to be after viol1
        else
          0
        end
      end

    end
  end
end; end
