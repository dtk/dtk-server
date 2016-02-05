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
  class ConfigAgent
    module Adapter
      def self.load(type)
        return nil unless type
        return Agents[type] if Agents[type]
        klass = self
        begin
          Lock.synchronize do
            r8_nested_require('adapter', type)
          end
          klass = const_get Aux.camelize(type.to_s)
        rescue LoadError
          raise Error.new("cannot find config agent adapter for type (#{type})")
        end
        Agents[type] = klass.new()
      end
      Lock = Mutex.new
      Agents = {}
    end
  end
end