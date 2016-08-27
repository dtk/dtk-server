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
  class ContentInput::Diff
    class SerializedHash
      class Set < self
        module Key
          ADDED    = 'ADDED'
          DELETED  = 'DELETED'
          MODIFIED = 'MODIFIED'
        end
        KEYS = [:added, :deleted, :modified]
        def self.create_info(opts)
          KEYS.inject(base_hash) do |h, key|
            (opts[key] || []).empty? ? h : h.merge(Key.const_get(key.upcase) => opts[key])
          end
        end
      end

    end
  end
end; end
