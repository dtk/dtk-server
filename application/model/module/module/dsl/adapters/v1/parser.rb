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
module DTK; class ModuleDSL; class V1
  class Parser < ::DTK::ModuleDSL::Parser
    private

    # updates both @components_hash and @remote_link_defs
    def process_remote_link_defs!(library_idh)
      return if @remote_link_defs.empty?
      # process all @remote_link_defs in this module
      @remote_link_defs.each do |remote_cmp_type, remote_link_def|
        config_agent_type = remote_link_def.values.first[:config_agent_type]
        remote_cmp_ref = component_ref_from_cmp_type(config_agent_type, remote_cmp_type)
        if cmp_pointer = @components_hash[remote_cmp_ref]
          remote_link_def.delete(:local_cmp_ref)
          (cmp_pointer['link_def'] ||= {}).merge!(remote_link_def)
          @remote_link_defs.delete(remote_cmp_type)
        end
      end

      # process remaining @remote_link_defs to see if in stored modules
      return if @remote_link_defs.empty?
      sp_hash = {
        cols: [:id, :ref, :component_type],
        filter: [:oneof, :component_type, @remote_link_defs.keys]
      }
      stored_remote_cmps = library_idh.create_object().get_children_objs(:component, sp_hash, keep_ref_cols: true)
      ndx_stored_remote_cmps = stored_remote_cmps.inject({}) { |h, cmp| h.merge(cmp[:component_type] => cmp) }
      @remote_link_defs.each do |remote_cmp_type, remote_link_def|
        if remote_cmp = ndx_stored_remote_cmps[remote_cmp_type]
          remote_cmp_ref = remote_cmp[:ref]
          cmp_pointer = @stored_components_hash[remote_cmp_ref] ||= { 'link_def' => {} }
          remote_link_def.delete(:local_cmp_ref)
          cmp_pointer['link_def'].merge!(remote_link_def)
          @remote_link_defs.delete(remote_cmp_type)
        end
      end

      # if any @remote_link_defs left they are dangling refs
      @remote_link_defs.each do |remote_cmp_type, remote_cmp_info|
        set_to_dangling_link?(remote_cmp_type, remote_cmp_info)
      end
    end

    def set_to_dangling_link?(remote_cmp_type, remote_cmp_info)
      # TODO: may see if can put :local_cmp_ref so can use remote_cmp_info[:local_cmp_ref]
      if remote_cmp_info.size != 1
        Log.error('remote_cmp_info has unexpected size (<>1)')
        return
      end
      if local_cmp_ref = remote_cmp_info.values.first[:local_cmp_ref]
        local_ld_type = "local_#{remote_cmp_type}"
        if pntr = ((@components_hash[local_cmp_ref] || {})['link_def'] || {})[local_ld_type]
          pntr.merge!(dangling: true)
        end
      end
    end
  end
end; end; end