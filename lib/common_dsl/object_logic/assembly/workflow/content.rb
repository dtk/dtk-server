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
module DTK; module CommonDSL
  module ObjectLogic; class Assembly
    class Workflow
      class Content < ContentInputHash
        require_relative('content/subtask')

        module HashKey
          include CommonDSL::Parse::CanonicalInput::HashKey
        end

        def initialize(content)
          super()
          @content = content
        end
        private :initialize
        
        def self.generate_content_input(content)
          new(content).generate_content_input!
        end

        def generate_content_input!
          set?(:Name, @content[HashKey::Name])
          set?(:SubtaskOrder, @content[HashKey::SubtaskOrder])
          if subtasks = @content[HashKey::Subtasks]
            set?(:Subtasks, Subtask.generate_content_input(subtasks))
          end

          if @content.has_key?(:flatten)
            #no op; we are pruning out :flatten 
          end
          if dsl_location = @content[HashKey::Import]
            set(:Import, dsl_location)
            # TODO: DTK-2680: making this hidden meaning import statement wil now show up in dsl; later want to support in workflow explicit import
            set(:HideImportStatement, true)
          end

          merge!(uninterpreted_keys)
          self
        end        
        
        private

        INTERPRETED_KEYS = [HashKey::Name, HashKey::SubtaskOrder, HashKey::Subtasks, HashKey::Flatten, HashKey::Import]
        def uninterpreted_keys
          (@content.keys - INTERPRETED_KEYS).inject(ContentInputHash.new) { |h, k| h.merge(k => @content[k]) }
        end
        
      end
    end
  end; end
end; end
