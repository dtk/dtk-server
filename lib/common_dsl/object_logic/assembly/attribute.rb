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
  module ObjectLogic
    class Assembly
      class Attribute < ContentInputHash
        require_relative('attribute/diff')

        def initialize(type, attribute)
          super()
          @type      = type
          @attribute = attribute
        end
        private :initialize

        # type can be :assembly, :node, :component
        # opts - depends on type
        def self.generate_content_input?(type, attributes, opts = {})
          content_input_attributes = attributes.inject(ContentInputHash.new) do |h, attribute| 
            content_input_attr = create(type, attribute, opts).generate_content_input?
            content_input_attr ? h.merge!(attribute_name(attribute) => content_input_attr) : h
          end
          content_input_attributes.empty? ? nil : sort(content_input_attributes)
        end
        
        def generate_content_input?
          unless prune?
            set_id_handle(@attribute)
            set(:Value,  attribute_value)
            if tags = tags?
              add_tags!(tags)
            end
            self
          end
        end

        def skip_for_generation?
          super or matches_tag_type?(:desired__derived__propagated) or matches_tag_type?(:actual)
        end

        ### For diffs
        def diff?(attribute_parse, qualified_key)
          unless skip_for_generation?
            cur_val = val(:Value)
            new_val = attribute_parse.val(:Value)
            create_diff?(cur_val, new_val, qualified_key)
          end
        end

        def self.diff_set(attributes_gen, attributes_parse, qualified_key, _opts = {})
          # The method array_of_diffs_on_matching_keys; so assuming that user is not adding attributes
          # and by design not erroneously catching hidden attributes, which will show up in self (attribute_gen),
          # but not attributes_parse
          array_of_diffs_on_matching_keys(attributes_gen, attributes_parse, qualified_key)
        end

        private

        # Could be overwritten
        def prune?
          false
        end

        # Could be overwritten
        def tags?
          nil
        end
        
        def self.create(type, attribute, opts = {})
          case type
          when :assembly
            new(type, attribute)
          when :node
            Node::Attribute.new(type, attribute)
          when :component
            Component::Attribute.new(type, attribute, opts)
          else
            fail Error, "Illegal type '#{type}'"
          end
        end

        def self.sort(content_input_attributes)
          content_input_attributes.keys.sort.inject(ContentInputHash.new) do |h, key|
            h.merge(key => content_input_attributes[key])
          end
        end

        def attribute_value
          @attribute_value ||= @attribute.convert_value_to_ruby_object(value_field: :attribute_value, donot_raise_error: true)
        end

        def attribute_name
          self.class.attribute_name(@attribute)
        end

        def self.attribute_name(attribute)
          attribute.display_name
        end

      end
    end
  end
end; end

