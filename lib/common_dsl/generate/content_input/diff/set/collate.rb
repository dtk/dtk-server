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
module DTK; class CommonDSL::Generate::ContentInput::Diff
  class Set 
    module Collate
      module Mixin
        def collate
          add_to_collate!(Collated.new)
        end
        
        def add_to_collate!(collated)
          @added.each { |added_diff| collated.add!(self, :added, added_diff) }
          @deleted.each { |deleted_diff| collated.add!(self, :deleted, deleted_diff) }
          @modified.each { |diff| diff.add_to_collate!(collated) }
          collated
        end
        
      end
    end
  end
end; end


