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
  module TargetHelper
    def ret_target_subtype
      (ret_request_params(:subtype) || :instance).to_sym
    end

    def ret_iaas_type(iaas_type_field = :iaas_type)
      iaas_type = (ret_non_null_request_params(iaas_type_field)).to_sym
      # check iaas type is valid
      supported_types = ::R8::Config[:ec2][:iaas_type][:supported]
      unless supported_types.include?(iaas_type.to_s.downcase)
        fail ::DTK::ErrorUsage.new("Invalid iaas type '#{iaas_type}', supported types (#{supported_types.join(', ')})")
      end
      iaas_type
    end
  end
end