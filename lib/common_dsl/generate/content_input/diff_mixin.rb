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
module DTK; module CommonDSL::Generate
  class ContentInput
    module DiffMixin
      # Main template-specific diff instance method call; Concrete classes overwrite this
      def diff?(_parse_object, _qualified_key = Diff::QualifiedKey.new)
        raise Error::NoMethodForConcreteClass.new(self.class)
      end
      
      def aggregate_diffs?(qualified_key, &body)
        self.class::Diff.aggregate?(qualified_key: qualified_key, id_handle: id_handle, &body)
      end
      
      def create_diff?(cur_val, new_val, qualified_key)
        self.class::Diff.diff?(cur_val, new_val, qualified_key: qualified_key, id_handle: id_handle)
      end

      # when comparing content of gen_hash to parse_hash this indicates what gen_hash keys to ignore
      def ignore_for_diff_to_parse?
        # TODO: want to change so ignore hidden and all except asserted, i.e., non-hidden asserted
        # hidden objects will appear in gen_hash but not parse_hash
        matches_tag_type?(:hidden)
      end

    end
  end
end; end
