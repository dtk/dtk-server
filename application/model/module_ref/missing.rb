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
  class ModuleRef
    class Missing
      attr_reader :module_name, :namespace
      def initialize(module_name, namespace)
        @module_name = module_name
        @namespace = namespace
      end

      def error
       Error.new(@module_name, @namespace)
      end

      class Error < ErrorUsage
        def initialize(module_name, namespace)
          super("Missing module ref '#{namespace}:#{module_name}'")
        end
      end
    end
  end
end