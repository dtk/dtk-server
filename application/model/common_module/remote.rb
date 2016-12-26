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
  class CommonModule
    module Remote
      def self.list(project, opts = {})
        rsa_pub_key = opts[:rsa_pub_key]
        Repo::Remote.new.list_module_info(:service_module, rsa_pub_key, opts.merge!(ret_versions_array: true))
      end

      # opts can have keys:
      #   :donot_raise_error
      def self.get_module_info(project, remote_params, rsa_pub_key, opts = {})
        ret = {}
        if raw_service_info = Info::Service.get_remote_module_info?(project, rsa_pub_key, remote_params)
          ret.merge!(service_info: transform_from_raw_remote_module_info(raw_service_info))
        end
        if raw_component_info = Info::Component.get_remote_module_info?(project, rsa_pub_key, remote_params)
          ret.merge!(component_info: transform_from_raw_remote_module_info(raw_component_info))
        end

        unless ret.empty?
          ret.merge(version: remote_params.version || intersect_versions(raw_service_info, raw_component_info))
        else
          if opts[:donot_raise_error]
            ret
          else
            fail ErrorUsage, "Module '#{remote_params.pp_module_ref}' not found in the #{Term.remote_ref}"
          end
        end     
      end

      def self.publish(project, local_params, remote_params, rsa_pub_key)
        module_info = get_module_info(project, remote_params, rsa_pub_key, donot_raise_error: true)
        fail ErrorUsage, "The publish command failed because the module '#{remote_params.pp_module_ref}' is already on the #{Term.remote_ref}" unless module_info.empty?
        
        # TODO: stub for DTK-2806
        nil
      end

      private

      module Term
        def self.remote_ref
          'DTKN Catalog'
        end
      end
    
      def self.transform_from_raw_remote_module_info(raw_info)
        { remote_repo_url: raw_info[:remote_repo_url] }
      end

      # TODO: DTK-2766: consider handling condition where service module at some version x requires component module
      #       at another version; in this case want to use the different versions of these modules.
      #       Need to figure out best version to use for combined; default is the service module version
      #       Alternative is to fix up modules that have different versions
      def self.intersect_versions(raw_service_info, raw_component_info)
        if raw_service_info
          if raw_component_info
            if raw_service_info[:latest_version] == raw_component_info[:latest_version]
              raw_service_info[:latest_version]
          else
              Aux.latest_version?(raw_service_info[:versions] && raw_component_info[:versions]) || 
                fail(ErrorUsage, "Mismatch between component info and service info versions")
            end
          else
            raw_service_info[:latest_version]
          end
        elsif raw_component_info
          raw_component_info[:latest_version]
        else
          fail ErrorUsage, "Unexpected that both raw_component_info and raw_component_info are nil"
        end
      end
      

    end
  end
end
