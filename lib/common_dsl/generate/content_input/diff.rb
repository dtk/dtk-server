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
    class Diff < ::DTK::Diff
      module Mixin
        # Main template-specific diff instance method call; Concrete classes overwrite this
        def diff?(_object2)
          raise Error::NoMethodForConcreteClass.new(self.class)
        end

        def aggregate_diffs?(key, &body)
          self.class::Diff.aggregate?(key: key, id_handle: id_handle, &body)
        end

        def create_diff?(key, cur_val, new_val)
          self.class::Diff.diff?(cur_val, new_val, key: key, id_handle: id_handle)
        end

      end
      
      module ClassMixin
        # Main template-specific diff class method call; Concrete classes overwrite this
        def compute_diff_object?(_objects1, _objects2)
          raise Error::NoMethodForConcreteClass.new(self)
        end

        def diff_set_from_hashes(gen_hash, parse_hash)
          self::Diff.between_hashes(gen_hash, parse_hash)
        end

        def array_of_diffs_on_matching_keys(gen_hash, parse_hash)
          self::Diff.array_of_diffs_on_matching_keys(gen_hash, parse_hash)
        end

      end
    end
  end
end; end
