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
  module Service::Reified
    # Reified::Component is an abstract class that roots reified service components
    class Component

      def initialize(service_component)
        @service_component = service_component
        # These elements of this hash get set on demand
        @cached_attributes = {}
        @cached_connected_components = {} #cache connected objects
      end

      def clear_attribute_cache!
        @service_component.clear_attribute_cache!
        @cached_attributes = {}
      end

      def use_and_set_attribute_cache(attribute_name, &body)
        @cached_attributes[attribute_name] ||= yield
      end
      
      def use_and_set_connected_component_cache(conn_component_type, &body)
        @cached_connected_components[conn_component_type] ||= yield
      end
      
      def get_attribute_value(attribute_name)
        get_attribute_values(attribute_name).first
      end
      
      # returns array with same length as names with values for each name it finds
      def get_attribute_values(*attribute_names)
        ndx_values = get_ndx_attribute_values(*attribute_names)
        attribute_names.map { |name| ndx_values[name] }
      end
      
      def get_ndx_attribute_values(*attribute_names)
        ndx_attrs = get_ndx_service_component_attributes
        attribute_names.inject({}) do |h, name| 
          attr = ndx_attrs[name]
          attr ? h.merge(name => attr.value) : h
        end
      end
      
      def update_and_propagate_dtk_attribute(attribute_name, attribute_value)
        update_and_propagate_dtk_attributes({ attribute_name => attribute_value}).first
      end
      
      # opts can have keys
      #  :prune_nil_values - Boolean (default false)
      def update_and_propagate_dtk_attributes(name_value_pairs, opts = {})
        ret = name_value_pairs.values
        name_value_pairs = name_value_pairs.reject{ |a, v| v.nil? } if opts[:prune_nil_values]
        return ret if name_value_pairs.empty?
        
        attr_rows_to_prop = []
        dtk_attributes    = get_dtk_attributes(*name_value_pairs.keys)
        values            = name_value_pairs.values
        dtk_attributes.each_with_index do |dtk_attribute, i|
          value = values[i]
          attr_rows_to_prop << { id: dtk_attribute.id, value_asserted: value }
        end
        attr_mh = dtk_attributes.first.model_handle
        Attribute.update_and_propagate_attributes(attr_mh, attr_rows_to_prop)
        ret
      end
      
      def get_connected_dtk_component_ids(link_def_type)
        @service_component.get_connected_dtk_component_ids(link_def_type)
      end
      
      def dtk_component
        @service_component.dtk_component
      end


      # For handling Attributes as methods
      def method_missing(attribute_method, *args, &body)
        if legal_attribute_method?(attribute_method) 
          use_and_set_attribute_cache(attribute_method) { get_attribute_value(attribute_method) }
        else
          super
        end
      end
      def respond_to?(attribute_method)
        legal_attribute_method?(attribute_method)
      end
      
      private
      
      def legal_attribute_method?(attribute_method)
        self.class.legal_attributes.include?(attribute_method)
      end
      
      def self.legal_attributes
        Log.error("Abstract method that should be overwritten for class '#{self}'")
        []
      end
      
      def get_dtk_attribute(attribute_name)
        get_dtk_attributes(attribute_name).first
      end
      
      def get_dtk_attributes(*attribute_names)
        get_service_component_attributes(*attribute_names).map { |a| a && a.dtk_attribute }
      end
      
      def get_service_component_attributes(*attribute_names)
        ndx_attrs = get_ndx_service_component_attributes
        attribute_names.map { |name| ndx_attrs[name] }          
        end
      
      def get_ndx_service_component_attributes
        @service_component.get_attributes.inject({}) { |h, attr| h.merge(attr.name.to_sym => attr) }
      end
      
    end
  end
end
