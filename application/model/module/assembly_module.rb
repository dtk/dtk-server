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
  class AssemblyModule
    extend Aux::CommonClassMixin
    require_relative('assembly_module/component')
    require_relative('assembly_module/service')

    def initialize(assembly)
      @assembly                = assembly
      @assembly_module_version = self.class.assembly_module_version(assembly)
    end

    # opts can have keys:
    #   :do_not_raise
    def self.delete_modules?(assembly, opts = {})
      Component.new(assembly).delete_modules?(skip_service_module_branch: true)
      Service.new(assembly).delete_module?(do_not_raise: opts[:do_not_raise])
    end

    def assembly_instance
      @assembly
    end

    private

    attr_reader :assembly_module_version

    def self.assembly_module_version(assembly)
      ModuleVersion.ret(assembly)
    end

  end
end
