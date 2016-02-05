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
  module ParsedDSL
    class ServiceModule
      def initialize
        @empty               = true
        @assembly_raw_hashes = {}
        @display_name        = nil
        @module_refs         = nil
        @assembly_workflows  = nil
      end

      attr_reader :display_name, :assembly_raw_hashes

      def component_module_refs
        (@module_refs && @module_refs.component_modules) || {}
      end

      def assembly_workflows
        @assembly_workflows || {}
      end

      def add_assembly_raw_hash(name, raw_hash)
        @assembly_raw_hashes[name] = raw_hash
      end

      def add(info =  {})
        @empty              = false
        @display_name       = info[:display_name]
        @module_refs        = info[:module_refs]
        @assembly_workflows = info[:assembly_workflows]
        self
      end

      def empty?
        @empty
      end

    end
  end
end