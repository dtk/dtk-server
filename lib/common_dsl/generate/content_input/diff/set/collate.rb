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
        
        # opts can have keys
        #  :qualified_key
        def add_to_collate!(collated, parent_qualified_key = QualifiedKey.new)
          qualified_key =  parent_qualified_key.create_with_new_element?(type_print_form, @key) 
          
          @added.each do |added_diff|
            collated.add!(self, :added, qualified_key: qualified_key.print_form, added_diff: added_diff)
          end
          
          @deleted.each do |deleted_diff|
            collated.add!(self, :deleted, qualified_key: qualified_key.print_form, deleted_diff: deleted_diff)
          end
          
          @modified.each do |diff|
            diff.add_to_collate!(collated, qualified_key)
          end
          collated
        end
        
      end
    end
  end
end; end


