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
  # New class for Service instances
  class Service
    r8_nested_require('service', 'target')

    def initialize(assembly_instance)
      @assembly_instance = assembly_instance
      @components        = nil
    end
    private :initialize

    # Returns a hash that has key for each component_types and whose value is an array (possibly empty) matching type
    def self.ndx_matching_components?(components, component_types)
      ret = {}
      ndx_component_types = {} 
      component_types.each do |cmp_type| 
        ret[cmp_type] = [] 
        ndx_component_types.merge!(cmp_type.gsub('::', '__') => cmp_type) 
      end

      components.each do |cmp| 
        if cmp_type = ndx_component_types[cmp.get_field?(:component_type)]
          ret[cmp_type] << cmp
        end
      end
      ret
    end

    private

    def components
      @components ||= @assembly_instance.get_info__flat_list(detail_level: 'components').select { |r| r[:nested_component] }.map { |r| r[:nested_component] }
    end
  end
end
