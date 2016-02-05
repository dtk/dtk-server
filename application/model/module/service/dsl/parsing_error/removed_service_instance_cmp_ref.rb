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
module DTK; class ServiceModule
  class ParsingError
    class RemovedServiceInstanceCmpRef < self
      attr_reader :cmp_ref_info_list
      def initialize(cmp_ref_info_list, opts = {})
        super(err_msg(cmp_ref_info_list), opts)
        # each element can be a component ref object or a hash
        @cmp_ref_info_list = cmp_ref_info_list
      end

      private

      def err_msg(cmp_ref_info_list)
        what = (cmp_ref_info_list.size == 1 ? 'A component' : 'Components')
        refs = cmp_ref_info_list.map { |cmp_ref_info| print_form(cmp_ref_info) }.compact.join(',')
        is = (cmp_ref_info_list.size == 1 ? 'is' : 'are')
        does = (cmp_ref_info_list.size == 1 ? 'does' : 'do')
        "#{what} '#{refs}' that #{is} referenced in service instance cannot be deleted"
      end

      def print_form(cmp_ref_info)
        ret = ComponentRef.print_form(cmp_ref_info)
        if version = cmp_ref_info[:version]
          ret = "#{ret}(#{version})"
        end
        ret
      end
    end
  end
end; end