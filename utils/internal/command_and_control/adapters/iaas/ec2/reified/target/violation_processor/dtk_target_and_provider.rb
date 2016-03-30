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
  class CommandAndControlAdapter::Ec2::Reified::Target::ViolationProcessor
    # TODO: 2487: This is temporay bridge functionality until we remove the dtk target and provider objects
    class DtkTargetAndProvider
      def initialize(reified_target, ndx_components, project)
        @sample_vpc     = sample_vpc(ndx_components)
        @target_service = reified_target.target_service
        @project_idh    = project.id_handle
      end
      
      def update_or_create
        provider = update_or_create_provider
        update_or_create_target(provider)
      end
      
      private
      
      def update_or_create_provider
        provider_name = @target_service.display_name
        if provider = Target::Template.provider_exists?(@project_idh, provider_name) 
          provider.update(iaas_properties: iaas_properties, display_name: provider_name)
        else
          iaas_type  = 'ec2'
          provider = Target::Template.create_provider?(@project_idh, iaas_type, provider_name, iaas_properties)
        end
        provider
      end
      
      def update_or_create_target(provider)
        if target = @target_service.target
          target.update({iaas_properties: iaas_properties, parent_id: provider.id()})
        else
          target_type = :ec2_vpc
          target = Target::Instance.create_target(target_type, @project_idh, provider, iaas_properties)
        end
        target
      end
      
      def iaas_properties 
        {
          :key    => @sample_vpc.aws_access_key_id,
          :secret => @sample_vpc.aws_secret_access_key
        }
      end
      
      def sample_vpc(ndx_components)
        ndx_components[:vpc].first || fail(Error, "Unexpected that there are no vpc components")
      end
    end
  end
end

