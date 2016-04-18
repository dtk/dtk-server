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
module DTK; class Target
  class Instance
    module DefaultTarget
      # opts can have keys
      #   :ret_singleton_target - Boolean (default: false); if true means if no default_target
      #                           it looks to see if there is a singleton target 
      #   :prune_builtin_target - Boolean (default: false; if true means prune out  builtin target
      def self.get(target_mh, opts = {})
        cols = [:id, :display_name, :group_id, :parent_id]
        sp_hash = {
          cols: cols,
          filter: [:eq, :is_default_target, true]
        }
        targets = Target::Instance.get(target_mh, sp_hash)
        if opts[:prune_builtin_target]
          targets.reject!(&:is_builtin_target?) 
        end
        if opts[:ret_singleton_target] and targets.size == 0
          targets = Target::Instance.get(target_mh, cols: cols)
          targets.reject!(&:is_builtin_target?) if opts[:prune_builtin_target]
        end
        if targets.size < 2
          targets.first
        else
          if opts[:return_all]
            targets
          else
            Log.error("Unexpected that more than 1 target is returned") unless opts[:ret_singleton_target]
            nil
          end
        end
      end

      # returns current_default_target
      # opts can be
      #   :current_default_target (computed already)
      #   :update_workspace_target
      def self.set(target, opts = {})
        ret = current_default_target = opts[:current_default_target] || get(target.model_handle())
        return ret unless target

        if current_default_target && (current_default_target.id == target.id)
          fail ErrorUsage::Warning.new("Default target is already set to #{current_default_target[:display_name]}")
        end

        all_default = get(target.model_handle(), { return_all: true })
        all_default = all_default.is_a?(Array) ? all_default : [all_default]

        Model.Transaction do
          all_default.each do |default|
            default.update(is_default_target: false)
          end
          target.update(is_default_target: true)
          if opts[:update_workspace_target]
            # also set the workspace with this target
            Workspace.set_target(target, mode: :from_set_default_target)
          end
        end
        ret
      end
    end
  end
end; end
