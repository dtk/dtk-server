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

        def initialize(content)
          super()
          @content = content
        end
        private :initialize
        
        def self.generate_content_input(content)
          new(content).generate_content_input!
        end

        def generate_content_input!
          set?(:SubtaskOrder, @content[:subtask_order])
          if subtasks = @content[:subtasks]
            set?(:Subtasks, Subtask.generate_content_input(subtasks))
          end

          if @content.has_key?(:flatten)
            #no op; we are pruning out :flatten 
          end
          if dsl_location = @content[:dsl_location]
            add_tags!([:hidden, dsl_location_tag(dsl_location)])
          end

          merge!(uninterpreted_keys)
          pp [:debug, self]
          self
        end        
        
        private

        def dsl_location_tag(dsl_location)
          "dsl_location=#{dsl_location}".to_sym
        end

        INTERPRETED_KEYS = [:subtask_order, :subtasks, :flatten, :dsl_loaction]
        def uninterpreted_keys
          to_add = (@content.keys - INTERPRETED_KEYS).inject(ContentInputHash.new) { |h, k| h.merge(k => @content[k]) }
          change_symbols_to_strings(to_add)
        end
        
        def change_symbols_to_strings(obj)
          if obj.kind_of?(::Hash)
            obj.inject({}) { |h, (k, v)| h.merge(k.to_s => change_symbols_to_strings(v)) }
          elsif obj.kind_of?(::Array)
            obj.map { |el| change_symbols_to_strings(el) }
          elsif obj.kind_of?(::Symbol)
            obj.to_s
          else
            obj
          end
        end

      end
    end
  end; end
end; end
