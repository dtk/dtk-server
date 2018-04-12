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
module DTK; class Assembly::Instance
  module Describe
    require_relative('describe/service_instance')
    require_relative('describe/components')
    require_relative('describe/actions')
    require_relative('describe/dependencies')

    def describe(path)
      describe_adapter, params = ret_adapter_and_params_from_path(path)
      describe_class = load_for(describe_adapter)

      raise ErrorUsage, "Unexpected that describe adapter #{describe_class} does not implement describe method!" unless describe_class.respond_to?(:describe)

      describe_class.describe(self, params)
    end

    def load_for(describe_adapter)
      self.class.const_get describe_adapter.to_s.split(/ |\_|\-/).map(&:capitalize).join("")
    end

    def ret_adapter_and_params_from_path(path)
      return 'service_instance' unless path
      adapter, *params = path.split(/\//)
      return adapter, params
    end

  end
end; end
