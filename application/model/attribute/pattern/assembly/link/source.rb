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
module DTK; class Attribute::Pattern
  class Assembly; class Link
    # for attribute relation sources
    class Source < self
      def self.create_attr_pattern(base_object, source_attr_term, source_is_antecdent)
        attr_term, fn, node_cmp_type = Simple.parse(source_attr_term) ||
                       VarEmbeddedInText.parse(source_attr_term)
        unless attr_term
          fail ErrorUsage::Parsing::Term.new(source_attr_term, :source_attribute)
        end
        attr_pattern = super(base_object, attr_term)
        if node_cmp_type
          attr_pattern.set_component_instance!(node_cmp_type)
          local_or_remote = (source_is_antecdent ? :remote : :local)
          attr_pattern.local_or_remote = local_or_remote
        end

        new(attr_pattern, fn, attr_term)
      end

      attr_reader :attribute_pattern, :fn
      def attribute_idh
        @attribute_pattern.attribute_idhs.first
      end

      def component_instance
        @attribute_pattern.component_instance()
      end

      private

      def initialize(attr_pattern, fn, attr_term)
        attr_idhs = attr_pattern.attribute_idhs
        if attr_idhs.empty?
          fail ErrorUsage.new("The term (#{attr_term}) does not match an attribute")
        elsif attr_idhs.size > 1
          fail ErrorUsage.new('Source attribute term must match just one, not multiple attributes')
        end
        @attribute_pattern = attr_pattern
        @fn = fn
      end

      module Simple
        def self.parse(source_term)
          if source_term =~ /^\$([a-zA-Z\-_0-9:\.\[\]\/]+$)/
            attr_term_x = Regexp.last_match(1)
            fn = nil
            attr_term, node_cmp_type = strip_special_symbols(attr_term_x)
            [attr_term, fn, node_cmp_type]
          end
        end

        private

        # TODO: need better way to do this; there is alsso an ambiguity if component level attribute host_address
        # returns [attr_term,node_cmp_type] where last term can be nil
        def self.strip_special_symbols(attr_term)
          ret = [attr_term, nil]
          split = attr_term.split('/')
          if split.size == 3 && split[2] == 'host_address'
            node_part, cmp_part, attr_part = split
            ret = ["#{node_part}/#{attr_part}", cmp_part]
          end
          ret
        end
      end

      module VarEmbeddedInText
        def self.parse(source_term)
          # TODO: change after fix stripping off of ""
          if source_term =~ /(^[^\$]*)\$\{([^\}]+)\}(.*)/
            str_part1 = Regexp.last_match(1)
            attr_term = Regexp.last_match(2)
            str_part2 = Regexp.last_match(3)
            fn = {
              function: {
                name: :var_embedded_in_text,
                constants: {
                  text_parts: [str_part1, str_part2]
                }
              }
            }
            node_cmp_type =  nil
            [attr_term, fn, node_cmp_type]
          end
        end

      end
    end
  end; end
end; end