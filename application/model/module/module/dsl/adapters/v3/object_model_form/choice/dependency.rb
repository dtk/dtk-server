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
module DTK; class ModuleDSL; class V3
  class ObjectModelForm; class Choice
    class Dependency < self
      def self.ndx_dep_choices(in_dep_cmps, base_cmp, opts = {})
        ret = {}
        if in_dep_cmps
          convert_to_hash_form(in_dep_cmps) do |conn_ref, conn_info|
            choices = convert_choices(conn_ref, conn_info, base_cmp, opts)
            ret.merge!(conn_ref => choices)
          end
        end
        ret
      end

      def self.dependencies?(choices_array, base_cmp, _opts = {})
        ret = nil
        choices_array.each do |choices|
          # can only express necessarily need component on same node; so if multipe choices only doing so iff all are internal
          unless choices.find { |choice| not choice.is_internal?() }
            # TODO: make sure it is ok to just pick one of these
            choice = choices.first
            ret ||= OutputHash.new
            add_dependency!(ret, choice.dependent_component(), base_cmp)
          end
        end
        ret
      end

      private

      def self.convert_choices(conn_ref, conn_info_x, base_cmp, opts = {})
        raw = { conn_ref => conn_info_x }
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
          opts_choices = opts.merge(conn_ref: conn_ref)
          choices.map { |choice| convert_choice(raw, choice, base_cmp, conn_info, opts_choices) }
        else
          dep_cmp_external_form = conn_info['component'] || conn_ref
          parent_info = {}
          dep_cmp_info = conn_info.merge('component' => dep_cmp_external_form)
          [convert_choice(raw, dep_cmp_info, base_cmp, parent_info, opts)]
        end
      end

      def self.convert_choice(raw, dep_cmp_info, base_cmp, parent_info = {}, opts = {})
        opts_convert = { no_default_link_type: true }.merge(opts)
        new(raw, dep_cmp_info['component'], base_cmp).convert(dep_cmp_info, base_cmp, parent_info, opts_convert)
      end
    end
  end; end
end; end; end