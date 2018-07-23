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
# TODO: this does some conversion of form; should determine what shoudl be done here versus subsequent parser phase
# TODO: does not check for extra attributes
module DTK; class ModuleDSL; class V2
  class ObjectModelForm
    class Choice < self
      require_relative('choice/link_attribute_ref')

      extend ComponentChoiceMixin

      def initialize
        @possible_link = OutputHash.new
      end
      
      def self.convert_choices(conn_ref, conn_info_x, base_cmp, opts = {})
        conn_info =
          if conn_info_x.is_a?(Hash)
            conn_info_x
          elsif conn_info_x.is_a?(Array) && conn_info_x.size == 1 && conn_info_x.first.is_a?(Hash)
            conn_info_x.first
          else
            base_cmp_name = component_print_form(base_cmp)
            err_msg = 'The following dependency on component (?1) is ill-formed: ?2'
            fail ParsingError.new(err_msg, base_cmp_name, conn_ref => conn_info_x)
          end
        if choices = conn_info['choices']
          opts_choice = opts.merge(conn_ref: conn_ref)
          choices.map { |choice| convert_choice(choice, base_cmp, conn_info, opts_choice) }
        else
          dep_cmp_external_form = conn_info['component'] || conn_ref
          parent_info = {}
          [convert_choice(conn_info.merge('component' => dep_cmp_external_form), base_cmp, parent_info, opts)]
        end
      end

      attr_reader :possible_link
      
      def has_attribute_mappings?
        ams = dep_component_info['attribute_mappings']
        not (ams.nil? || ams.empty?)
      end
      
      def is_internal?
        dep_component_info['type'] == 'internal'
      end
      
      def dependent_component
        self.possible_link.keys.first
      end
      
      def convert(dep_cmp_info, base_cmp, parent_info = {}, opts = {})
        unless dep_cmp_raw = dep_cmp_info['component'] || opts[:conn_ref]
          fail ParsingError.new('Dependency possible connection (?1) is missing component key', dep_cmp_info)
        end
        dep_cmp = convert_to_internal_cmp_form(dep_cmp_raw)
        ret_info = { 'type' => link_type(dep_cmp_info, parent_info, opts) }
        if order = order(dep_cmp_info)
          ret_info['order'] = order
        end
        in_attr_mappings = (dep_cmp_info['attribute_mappings'] || []) + (parent_info['attribute_mappings'] || [])
        unless in_attr_mappings.empty?
          ret_info['attribute_mappings'] = in_attr_mappings.map { |in_am| convert_attribute_mapping(in_am, base_cmp, dep_cmp, opts) }
        end
        self.possible_link.merge!(convert_to_internal_cmp_form(dep_cmp) => ret_info)
        self
      end

      def convert_attribute_mapping(input_am, base_cmp, dep_cmp, opts = {})
        # TODO: right now only treating constant on right hand side meaning only for <- case
        if input_am =~ /(^[^ ]+)[ ]*->[ ]*([^ ].*$)/
          dep_attr = Regexp.last_match(1)
          base_attr = Regexp.last_match(2)
          left = LinkAttributeRef.convert_simple(dep_attr, :dep, dep_cmp, :output)
          right = LinkAttributeRef.convert_simple(base_attr, :base, base_cmp, :input)
        elsif input_am =~ /(^[^ ]+)[ ]*<-[ ]*([^ ].*$)/
          dep_attr = Regexp.last_match(1)
          base_attr = Regexp.last_match(2)
          left = LinkAttributeRef.convert_base(base_attr, base_cmp, dep_attr, dep_cmp, :output, opts)
          right = LinkAttributeRef.convert_simple(dep_attr, :dep, dep_cmp, :input)
        else
          fail ParsingError.new('Attribute mapping (?1) is ill-formed', input_am)
        end
        { left => right }
      end

      private
      
      def order(dep_cmp_info)
        if ret = dep_cmp_info['order']
          unless LegalOrderVals.include?(ret)
            fail ParsingError.new("Value of order param (?1) is ill-formed; it should be one of (#{LegalOrderVals}.join(', '))", ret)
          end
          ret
        end
      end
      LegalOrderVals = ['after', 'before']
      
      def self.convert_choice(dep_cmp_info, base_cmp, parent_info = {}, opts = {})
        new.convert(dep_cmp_info, base_cmp, parent_info, opts)
      end

      def dep_component_info
        self.possible_link.values.first
      end
      
      DefaultLinkType = 'local'
      def link_type(link_info, parent_link_info = {}, opts = {})
        ret = nil
        loc = link_info['location'] || parent_link_info['location']
        if opts[:no_default_link_type] && loc.nil?
          return ret
        end
        loc ||= DefaultLinkType
        case loc
        when 'local' then 'internal'
        when 'remote' then 'external'
        else fail ParsingError::Location.new(loc)
        end
      end
      
    end
  end
end; end; end
