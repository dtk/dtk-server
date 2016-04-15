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
module DTK; class Task; class Template
  class ActionList
    class ConfigComponents < self
      def self.get(assembly, opts = {})
        # component_list_filter_proc includes clause to make sure no target refs
        opts_assembly_cmps = { seed: new(), filter_proc: component_list_filter_proc(opts) }
        assembly_cmps = assembly.get_component_info_for_action_list(opts_assembly_cmps)
        # NodeGroup.get_component_info_for_action_list looks for any components in inventory node groups
        ret = NodeGroup.get_component_info_for_action_list(assembly_cmps.nodes(), add_on_to: assembly_cmps)
        ret.set_action_indexes!()
      end
    end

    def nodes
      ndx_ret = {}
      each do |r|
        node = r[:node]
        ndx_ret[node[:id]] ||= node
      end
      ndx_ret.values()
    end

    private

    def self.component_list_filter_proc(opts = {})
      if cmp_type_filter = opts[:component_type_filter]
        lambda { |el| !target_ref?(el) and (el[:nested_component] || {})[:basic_type] == cmp_type_filter.to_s }
      else
        lambda { |el| !target_ref?(el) }
      end
    end

    def self.target_ref?(el)
      el[:node] and el[:node].is_target_ref? 
    end

  end
end; end; end
