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
  class LockedModuleRefs
    require_relative('locked_module_refs/common_module')
    require_relative('locked_module_refs/service_instance')

    def initialize(indexed_elements)
      @indexed_elements = indexed_elements # indexed_elements is hash indexed by module name
    end
    private :initialize
    
    attr_reader :indexed_elements

    def matching_module_ref?(module_name)
      self[module_name]
    end

    def module_refs_array
      self.indexed_elements.values
    end

    private

    def []=(mod_name, value)
      self.indexed_elements[key(mod_name)] = value
    end 
    
    def [](mod_name)
      self.indexed_elements[key(mod_name)]
    end 
    
    def delete(mod_name)
      self.indexed_elements.delete(key(mod_name))
    end
    
    # key into indexed_elements
    def self.key(mod_name)
      mod_name.to_sym
    end
    def key(mod_name)
      self.class.key(mod_name)
    end

  end
end
