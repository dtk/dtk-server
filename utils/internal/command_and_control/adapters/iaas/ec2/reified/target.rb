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
  module CommandAndControlAdapter::Ec2::Reified
    class Target < DTK::Service::Reified::Components
      r8_nested_require('target', 'component')
      r8_nested_require('target', 'violation_processor')
      r8_nested_require('target', 'violation')

      def initialize(target_service)
        super()
        @target_service = target_service.add_links_to_components!
      end

      def vpc_components
        get_all_components_of_type(:vpc)
      end

      def vpc_subnet_components
        get_all_components_of_type(:vpc_subnet)
      end

      def security_group_components
        get_all_components_of_type(:security_group)
      end

      # opts can have keys
      #  :use_and_set_cache - Boolean (default true)
      def get_all_components_of_type(component_type, opts = {})
        if "#{opts[:use_and_set_cache]}" == 'false'
          get_all_components_of_type_aux(component_type)
        else
          use_and_set_cache(component_type) { get_all_components_of_type_aux(component_type) }
        end
      end

      def assembly_instance
        @target_service.assembly_instance
      end

      def clear_all_attribute_caches!
        apply_to_all_components { |reified_cmp| reified_cmp.clear_attribute_cache! }
      end

      def matching_components(dtk_component_ids)
        ret = []
        return ret if dtk_component_ids.empty?
        # TODO: can make more efficient by passing in type of dtk_component_ids
        # so dont have to iterate over all types
        apply_to_all_components do |reified_cmp|
          if dtk_component_ids.include?(reified_cmp.dtk_component.id)
            ret << reified_cmp
          end
        end
        ret
      end

      private
      # applfies body to all reified components in target
      def apply_to_all_components(&body)
        Component::Type::All.each do |cmp_type|
          get_all_components_of_type(cmp_type).each { |reified_cmp| body.call(reified_cmp) }
        end
      end

      def get_all_components_of_type_aux(component_type)
        component_type_name = Component::Type.send(component_type)
        service_components = @target_service.matching_components?(component_type_name) || []
        service_components.map { |sc| component_class(component_type).new(self, sc) }
      end

      def component_class(component_type)
        Component.const_get(Aux.camelize(component_type.to_s))
      end
    end
  end
end

