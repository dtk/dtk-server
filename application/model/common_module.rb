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
  module CommonModule
    # Mixins need to go before common_module/service and common_module/component
    require_relative('common_module/mixin')
    require_relative('common_module/class_mixin')

    extend  CommonModule::ClassMixin
    include CommonModule::Mixin

    require_relative('common_module/service')
    require_relative('common_module/component')

    def self.list_assembly_templates(project)
      Service.list_assembly_templates(project)
    end

  end
end
