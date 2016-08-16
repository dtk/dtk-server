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
module DTK; module CommonModule::DSL::Generate
  class ContentInput 
    class Assembly
      class Attribute < ContentInput::Hash

        def initialize(type, attribute)
          super()
          @type      = type
          @attribute = attribute
        end
        private :initialize

        # type can be :assembly, :node, :component
        # opts - depends on type
        def self.generate_content_input?(type, attributes, opts = {})
          content_input_attributes = ContentInput::Array.new
          attributes.each do |attribute| 
            if content_input_attr = create(type, attribute, opts).generate_content_input?
              content_input_attributes << content_input_attr
            end
          end
          content_input_attributes.empty? ? nil : sort(content_input_attributes)
        end
        
        def generate_content_input?
          unless prune?
            set(:Name, attribute_name)
            set(:Value,  attribute_value)
            if tags = tags?
              add_tags!(tags)
            end
            self
          end
        end

        ### For diffs
        def diff?(attribute)
          # Only called if name are the same
          val1 = val(:Value)
          val2 = attribute.val(:Value)
          if val1.class == val2.class and val1 == val2
            Diff.base_new(val1, v1l2)
          end
        end

        def self.compute_diff_object?(attributes1, attributes2)
          Diff.objects_in_array?(:attribute, attributes1, attributes2)
        end

        def diff_key
          req(:Name)
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
          content_input_attributes.sort { |a, b| a.req(:Name) <=> b.req(:Name) }
        end

        def attribute_value
          @attribute_value ||= DTK::Attribute::Datatype.convert_value_to_ruby_object(@attribute, value_field: :attribute_value)
        end

        def attribute_name
          @attribute.display_name
        end

      end
    end
  end
end; end

