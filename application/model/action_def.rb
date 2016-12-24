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
  class ActionDef < Model
    require_relative('action_def/content')
    require_relative('action_def/dynamic_provider')
    def self.common_columns
      core_columns + [:method_name, :content, :component_component_id]
    end

    module Constant
      module Variations
      end
      extend Aux::ParsingingHelper::ClassMixin
      CreateActionName = 'create'
    end
    
    def self.get_action_def(id_handle, opts = {})
      sp_hash = {
        cols:   cols_from_opts(opts),
        filter: [:eq, :id, id_handle.get_id]
      }
      ret = aggregate_parameters?(get_objs(id_handle.createMH, sp_hash), opts)
      if ret.size == 1
        ret.first
      else
        Log.error("Unexpected that size (#{ret.size.to_s}) != 1")
        nil
      end
    end

    def self.get_matching_action_def?(component_template, method_name)
      if match = get_ndx_action_defs([component_template.id_handle], filter: [:eq, :method_name, method_name])[component_template.id]
        # will only be one element
        match.first
      end
    end

    def self.get_ndx_action_defs(cmp_template_idhs, opts = {})
      ret = {}
      return ret if cmp_template_idhs.empty?

      filter = [:oneof, :component_component_id, cmp_template_idhs.map { |cmp| cmp.get_id {} }]
      filter = [:and, filter, opts[:filter]] if opts[:filter]
      
      sp_hash = { cols:  cols_from_opts(opts), filter: filter }
      action_def_mh = cmp_template_idhs.first.createMH(:action_def)
      rows = get_objs(action_def_mh, sp_hash)
      aggregate_parameters?(rows, opts).each do |ad|
        (ret[ad[:component_component_id]] ||= []) << ad
      end
      ret
    end

    def commands
      parse_and_reify_content?.commands
    end

    def functions
      parse_and_reify_content?.functions
    end

    def docker
      parse_and_reify_content?.docker
    end

    def content
      parse_and_reify_content?
    end

    # if parse does not go through; raises parse error
    def self.parse(hash_content)
      Content.parse(hash_content)
    end

    private

    def self.cols_from_opts(opts = {})
      cols = (opts[:cols] ? (opts[:cols] + core_columns + [:component_component_id]).uniq : common_columns)
      opts[:with_parameters] ? cols + [:parameters] : cols
    end

    def self.aggregate_parameters?(rows, opts = {})
      ret = rows
      return ret unless opts[:with_parameters]

      ndx_by_action_def = {}
      rows.each do |r|
        action_def_id = r[:id]
        parameter = r.delete(:parameter)
        pntr = ndx_by_action_def[action_def_id] ||= r.merge(parameters: [])
        if parameter
          pntr[:parameters] << parameter
        end
      end
      ndx_by_action_def.values
    end

    def parse_and_reify_content?
      content = get_field?(:content)
      unless content.is_a?(Content)
        if content.is_a?(Hash)
          hash_content = content
          self[:content] = Content.parse(hash_content)
        else
          fail Error.new("Unexpected class type (#{content.class}")
        end
      end
      self[:content]
    end
  end
end
