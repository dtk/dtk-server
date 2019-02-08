#
# Copyright (C) 2010-2017 dtk contributors
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
module DTK; class  Assembly::Instance
  module Mixin
    def ret_adapter_and_params_from_path(path)
      return unless path
      adapter, *params = path.split(/\//)
      return adapter, params
    end

    def load_adapter_class(base, adapter_name)
      begin
        base.const_get("#{capitalize_adapter_name(adapter_name)}")
      rescue NameError => error
        fail ErrorUsage, "Unsupported path '#{adapter_name}'"
      end
    end

    def capitalize_adapter_name(adapter_name)
      adapter_name.to_s.split(/ |\_|\-/).map(&:capitalize).join("")
    end
  end
end; end