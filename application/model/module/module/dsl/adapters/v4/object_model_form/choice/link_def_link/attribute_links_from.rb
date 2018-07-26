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
module DTK; class ModuleDSL; class V4
  class ObjectModelForm; class Choice::LinkDefLink
    class AttributeLinksFrom < self
      def initialize(base_cmp, attribute_name, links_from_term, link_type)
        @base_cmp        = base_cmp
        @attribute_name  = attribute_name
        @links_from_term = links_from_term
        @link_type       = link_type
      end
      private :initialize

      def self.convert(base_cmp, attribute_name, links_from_term)
        [new(base_cmp, attribute_name, links_from_term, :external).convert,
        new(base_cmp, attribute_name, links_from_term, :internal).convert]
      end
      def convert
        ret_info = {
          'attribute_mappings' => self.attribute_mappings,
          'type' => self.link_type.to_s 
        }
        set_single_possible_link!(self.dep_cmp, ret_info)
        @dependency_name = self.dep_component_type
        self
      end

      protected
      
      attr_reader :base_cmp, :attribute_name, :links_from_term, :link_type

      def attribute_mappings
        [{ attribute_mappings_lhs => attribute_mappings_rhs }]
      end

      def attribute_mappings_lhs
        "#{self.dep_cmp}.#{::DTK::LinkDef::Link::AttributeMapping::AllAttributes::INTERNAL_NAME}"
      end

      def attribute_mappings_rhs
        "#{self.base_cmp}.#{self.attribute_name}"
      end

      ParsedLinksFromTerm = Struct.new(:component_type)
      def parsed_links_from_term
        @parsed_links_from_term ||= ret_parsed_links_from_term
      end

      def dep_cmp
        @dep_cmp ||= convert_to_internal_cmp_form(self.dep_component_type)
      end

      def dep_component_type
        @dep_component_type ||= self.parsed_links_from_term.component_type
      end

      private

      def ret_parsed_links_from_term
        if self.links_from_term.kind_of?(::String)
          if self.links_from_term.split('::').size < 3
            ParsedLinksFromTerm.new(self.links_from_term)
          end
        end || raise_parsing_error
      end
      
      def raise_parsing_error
        err_msg = "On the following links_from section on attribute '?1': ?2"
        fail ParsingError.new(err_msg, "#{base_cmp_print_form}.#{self.attribute_name}", self.links_from_term)
      end
      
    end
  end; end
end; end; end
