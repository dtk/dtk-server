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
      def self.get(target_mh, cols = [])
        cols = [:id, :display_name, :group_id] if cols.empty?
        sp_hash = {
          cols: cols,
          filter: [:eq, :is_default_target, true]
        }
        ret = Target::Instance.get_obj(target_mh, sp_hash)
        ret && ret.create_subclass_obj(:target_instance)
      end

      # returns current_default_target
      # opts can be
      #   :current_default_target (computed already)
      #   :update_workspace_target
      def self.set(target, opts = {})
        ret = current_default_target = opts[:current_default_target] || get(target.model_handle(), [:display_name])
        return ret unless target

        if current_default_target && (current_default_target.id == target.id)
          fail ErrorUsage::Warning.new("Default target is already set to #{current_default_target[:display_name]}")
        end

        Model.Transaction do
          current_default_target.update(is_default_target: false) if current_default_target
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