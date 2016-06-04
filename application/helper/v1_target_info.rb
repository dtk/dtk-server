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
module Ramaze::Helper
  module V1TargetInfoHelper
    TargetInfo = Struct.new(:target, :assembly_instance, :is_target_service)
    def ret_target_info(project)
      is_target_service = boolean_request_params(:is_target)
      target = nil
      target_assembly_instance =  nil
      if is_target_service
        opts[:is_target_service] = true
        target_name = assembly_name || "#{service_module[:display_name]}-#{assembly_template[:display_name]}"
        target = Service::Target.create_target_mock(target_name, project)
        target_assembly_instance = ret_assembly_instance_object?(:parent_service)
      else
        # this case is for service instance which are staged against a target service instance
        # which is giving  parameter 'parent-service' or getting default target 
        target_service = ret_target_service_with_default(:parent_service)
        raise_error_if_target_not_convereged(target_service)
        target = target_service.target
        target_assembly_instance = target_service.assembly_instance
      end
      TargetInfo.new(target, target_assembly_instance, is_target_service)
    end
  end
end
