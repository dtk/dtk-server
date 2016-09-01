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
module DTK
  class CommonDSL::Diff
    class Collated 
      def initialize
        @diffs = {}
      end

      Key = Struct.new(:type, :operation)
      # diff operation can be :added, :deleted, :modified
      def add!(diff, diff_operation, object)
        key = Key.new(diff.type, diff_operation)
        (@diffs[key] ||= []) << object
        self
      end

      def process
        Sort::ForProcess.sort_keys(@diffs.keys).each do |collate_key|
          diffs_of_same_type = @diffs[collate_key]
          diffs_of_same_type.each { |diff| diff.process }
        end
      end

      # opts can have keys
      #   :dsl_version (required)
      def serialize(opts = {})
        SerializedHash.create(opts) do |serialized_hash|
          Sort::ForSerialize.sort_keys(@diffs.keys).each do |collate_key|
            diffs_of_same_type = @diffs[collate_key]
            serialized_hash.add_collate_level_elements?(collate_key, diffs_of_same_type)
          end
        end
      end

      private

      class Sort
        def self.sort_keys(collate_keys)
          collate_keys.sort { |a_key, b_key| order_collate_keys(a_key, b_key) }
        end

        private

        def self.order_collate_keys(a_key, b_key)
          # lexigraphic ordering using type following by operation
          [type_order_mapping[a_key.type] || -1, op_order_mapping[a_key.operation] || -1] <=> 
            [type_order_mapping[b_key.type] || -1, op_order_mapping[b_key.operation] || -1]
        end

        def self.order_mapping(elements)
          elements.inject({}) {|h, el| h.merge(el => h.size) }
        end

        class ForSerialize < self
          private
          TYPE_ORDER = [:node, :component, :attribute]
          OP_ORDER   = [:added, :deleted, :modified]

          def self.type_order_mapping
            @type_order_mapping ||= order_mapping(TYPE_ORDER)
          end
          def self.op_order_mapping
            @op_order_mapping ||= order_mapping(OP_ORDER)
          end
        end

        class ForProcess < self
          private
          TYPE_ORDER = [:node, :component, :attribute]
          OP_ORDER   = [:added, :deleted, :modified]

          def self.type_order_mapping
            @type_order_mapping ||= order_mapping(TYPE_ORDER)
          end
          def self.op_order_mapping
            @op_order_mapping ||= order_mapping(OP_ORDER)
          end
        end

      end
    end
  end
end
