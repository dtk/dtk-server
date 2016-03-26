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
    r8_nested_require('service', 'component')
    r8_nested_require('service', 'reified')

    def initialize(assembly_instance)
      @assembly_instance = assembly_instance
      # @components is computed on demand and is an array with Service::Component elements
      @components = nil
    end
    private :initialize

    def matching_components?(component_type)
      self.class.ndx_matching_components?(components, [component_type]).first
    end
    # Returns a hash that has key for each component_types and whose value is an array (possibly empty) matching type
    # components is array with Service::Component elements
    def self.ndx_matching_components?(components, component_types)
      ret = {}
      if components.empty?
        return ret
      end
      if components.first.kind_of?(DTK::Component)
        components = Component.create_components_from_dtk_components(components)
      else
        fail(Error, "Unexpected component type '#{components.first.class}'") unless components.first.kind_of?(Component)
      end
      ret = component_types.inject({}) { |h, cmp_type| h.merge(cmp_type => []) }
      components.each do |cmp| 
        type = cmp.type
        ret[type] << cmp if component_types.include?(type)
      end
      ret
    end

    private

    def components
      return @components if @components
      dtk_components = @assembly_instance.get_info__flat_list(detail_level: 'components').map { |r| r[:nested_component] }
      @components = Component.create_components_from_dtk_components(dtk_components)
    end

    def components_from_dtk_components(dtk_components)
      self.class.components_from_dtk_components(dtk_components)
    end

    def self.components_from_dtk_components(dtk_components)
      dtk_components.map { |dtk_component| Component.new(dtk_component) }
    end
  end
end
