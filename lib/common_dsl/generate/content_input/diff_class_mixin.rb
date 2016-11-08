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
    module DiffClassMixin
      # opts can haev keys:
      #   :service_instance
      #   :impacted_files
      def diff_set_from_hashes(gen_hash, parse_hash, quaified_key, opts = {})
        self::Diff.between_hashes(gen_hash, parse_hash, quaified_key, opts)
      end
      
      def array_of_diffs_on_matching_keys(gen_hash, parse_hash, quaified_key)
        self::Diff.array_of_diffs_on_matching_keys(gen_hash, parse_hash, quaified_key)
      end
    end
  end
end; end
