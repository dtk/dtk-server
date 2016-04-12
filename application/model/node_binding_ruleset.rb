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
  class NodeBindingRuleset < Model
    r8_nested_require('node_binding_ruleset', 'factory')

    def self.common_columns
      [:id, :display_name, :type, :os_type, :rules, :ref]
    end

    def self.check_valid_id(model_handle, id)
      check_valid_id_default(model_handle, id)
    end

    def self.name_to_id(model_handle, name)
      return name.to_i if name.match(/^[0-9]+$/)
      sp_hash =  {
        cols: [:id],
        filter: [:eq, :ref, name]
      }
      name_to_id_helper(model_handle, name, sp_hash)
    end

    def self.object_type_string
      'node template'
    end

    def node_template_from_match_hash?(match_hash)
      if match = get_field?(:rules).find { |rule| rule_matches_condition?(rule, match_hash) }
        get_node_template(match[:node_template])
      end
    end
    def rule_matches_condition?(rule, match_hash)
      ! rule[:conditions].find { |k, v| match_hash[k] != v }
    end
    private :rule_matches_condition?
    # TODO: DTK-2489: deperacet below for above
    def find_matching_node_template(target)
      if match = CommandAndControl.find_matching_node_binding_rule(get_field?(:rules), target)
        get_node_template(match[:node_template])
      end
    end

    def clone_or_match(target, opts = {})
      update_object!(:type, :rules, :ref)
      case self[:type]
       when 'clone'
        clone(target, opts)
       when 'match'
        match(target, opts)
       else
        fail Error.new("Unexpected type (#{self[:type]}) in node binding ruleset")
      end
    end

    def ret_common_fields_or_that_varies
      ret = {}
      return ret unless self[:rules]
      first_time = true
      self[:rules].each do |rule|
        nt = rule[:node_template]
        RuleSetFields.each do |k|
          if ret[k] == :varies
            # no op
          elsif ret[k]
            ret[k] = :varies if ret[k] != nt[k]
          elsif first_time
            ret[k] = nt[k]
          else
            ret[k] = :varies
          end
        end
        first_time = false
      end
      ret
    end
    RuleSetFields = [:type, :image_id, :region, :size]

    private

    def match(_target, _opts = {})
      fail Error.new('TODO: not implemented yet')
    end

    def clone(target, opts = {})
      node_template = find_matching_node_template(target)
      override_attrs = opts[:override_attrs] || {}

      # special processing of :display_name
      display_name = override_attrs[:display_name] || get_field?(:ref)
      override_attrs.merge!(display_name: Node::Instance.get_unique_instance_name(model_handle(:node), display_name))

      clone_opts = node_template.source_clone_info_opts()
      new_obj = target.clone_into(node_template, override_attrs, clone_opts)
      new_obj && new_obj.id_handle()
    end

    def get_node_template(node_template_ref)
      sp_hash = {
        cols: [:id, :display_name, :external_ref, :group_id],
        filter: [:and, [:eq, :node_binding_rs_id, id()], [:eq, :type, 'image']]
      }
      ret = Model.get_objs(id_handle.createMH(:node), sp_hash).find { |r| r[:external_ref][:image_id] == node_template_ref[:image_id] }
      fail Error.new('Cannot find associated node template') unless ret
      ret
    end
  end
end
