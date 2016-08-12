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
# Assumption this file is loaded before Puppet is loaded
module DTK
  class PuppetLoader
    require 'yaml'
    YAML_DUMP_METHOD = ::YAML.method(:dump)

    def self.load
      load_aux unless @loaded
    end
    private
    
    def self.load_aux
      require 'puppet'
      @loaded = true
      undo_yaml_monkey_patch
    end

    def self.undo_yaml_monkey_patch(&body)
      ::YAML.class_eval do
        def self.dump(*args)
          YAML_DUMP_METHOD.call(*args)
        end
      end
      nil
    end
  end
end

