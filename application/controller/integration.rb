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
require 'ap'

module XYZ
  class IntegrationController < Controller

    def rest__docker_execute
      require 'debugger'; debugger
      docker_image, docker_command, puppet_manifest, execution_type, dockerfile = ret_request_params(:docker_image, :docker_command, :puppet_manifest, :execution_type, :dockerfile) 
       
      commander = Docker::Commander.new(docker_image, docker_command, puppet_manifest, execution_type, dockerfile)

      commander.run()
      rest_ok_response
    end

    def rest__spin_tenant
      username, password, email = ret_non_null_request_params(:username, :password, :email)

      # Rich: You have other params in request in case you need them

      ap ' Sync Started'
      ap username
      ap password
      ap email

      # Spin up tenants goes here

      # notify back repoman that tenant is ready and repoman will send email
      client = RepoManagerClient.new
      ap client.notify_tenant_ready(email, username)

      rest_ok_response
    end
  end
end
