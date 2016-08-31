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
    class SerializedHash < ::Hash
      require_relative('serialized_hash/term')

      # opts can have keys
      #   :dsl_version (required)
      def initialize(opts = {})
        super()
        unless @dsl_version = opts[:dsl_version]
          fail Error, "Unexpected that opts[:dsl_version] is nil"
        end
      end
      
      # opts can have keys
      #   :dsl_version (required)
      def self.create(opts = {}, &body)
        ret = new(opts)
        body.call(ret) # code in body will update ret
        ret
      end

      def add_collate_level_elements?(collate_key, diffs)
        serialized_diffs = diffs.map { |diff| diff.serialize(self) }
        unless serialized_diffs.empty?
          merge!(serialize_collate_key(collate_key) => serialized_diffs)
        end
        self
      end
      
      def serialize_add_element(add_diff)
        serialized_content = serialize_add_parse_object(add_diff.parse_object)
        { serialize_qualified_key(add_diff)  => serialized_content }
      end
      
      def serialize_delete_element(delete_diff)
        serialize_qualified_key(delete_diff)
      end
      
      def serialize_modify_element(modify_diff)
        { 
          serialize_qualified_key(modify_diff) =>  {
            Term::CURRENT_VAL => modify_diff.current_val,
            Term::NEW_VAL => modify_diff.new_val
          }
        }
      end

      private

      def serialize_collate_key(collate_key) 
        Term.diff_element_type(collate_key.type, collate_key.operation)
      end

      def serialize_add_parse_object(parse_object)
        # TODO: use @dsl_version to render yaml for parse_object
        serialize_add_parse_object_aux(parse_object)
      end

      # TODO: temp hack
      def serialize_add_parse_object_aux(obj)
        if obj.kind_of?(::Hash)
          obj.inject({}) { |h, (k, v)| h.merge(k => serialize_add_parse_object_aux(v)) }
        elsif obj.kind_of?(::Array)
          obj.map { |el| serialize_add_parse_object_aux(el) }
        else
          obj
        end
      end

      def serialize_qualified_key(diff_element)
        diff_element.qualified_key.print_form
      end

    end
  end
end

