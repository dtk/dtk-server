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
  class Assembly::Instance
    class ComponentLink
      require_relative('component_link/factory')
      require_relative('component_link/error')
      require_relative('component_link/print_form')

      module Mixin
        # opts can have keys:
        #   :link_name
        #   :external_dependency_assembly
        def add_component_link_from_name_params(base_component_name, dep_component_name, opts = {})
          args = [base_component_name, dep_component_name, opts]
          base_component = ComponentLink.component_object?(base_component_name, self) || Error.raise_bad_base_component(*args)
          dep_component = ComponentLink.component_object?(dep_component_name, opts[:external_dependency_assembly] || self) || Error.raise_bad_dep_component(*args)
          add_component_link(base_component, dep_component, opts)
        end
        
        # opts can have keys:
        #   :link_name
        def add_component_link(base_component, dep_component, opts = {})
          link_name = ComponentLink.find_and_check_link_name(base_component, dep_component,  link_name: opts[:link_name])
          ComponentLink::Factory.new(self, base_component.id_handle, dep_component.id_handle, link_name).add?
        end

        # opts can have keys:
        #   :context
        #   :filter
        def list_component_links(opts = {})
          PrintForm.list_component_links(self, opts)
        end
        
        def list_possible_component_links
          PrintForm.list_possible_component_links(self)
        end
      end

      def initialize(assembly_instance)
        @assembly_instance = assembly_instance
      end
      
      def self.print_form_hash(component_link)
        PrintForm.print_form_hash(component_link)
      end

      def self.delete(port_link_idhs)
        if port_link_idhs.is_a?(Array)
          return if port_link_idhs.empty?
        else
          port_link_idhs = [port_link_idhs]
        end
        
        aug_attr_links = get_augmented_attribute_links(port_link_idhs)
        attr_mh = port_link_idhs.first.createMH(:attribute)
        Model.Transaction do
          AttributeLink.update_for_delete_links(attr_mh, aug_attr_links)
          port_link_idhs.map { |port_link_idh| Model.delete_instance(port_link_idh) }
        end
      end
      
      # opts can have keys:
      #   :link_name
      def self.find_and_check_link_name(base_component, dep_component, opts = {})
        matching_link_types = matching_link_types(base_component, dep_component)
        unique_link_name?(matching_link_types, opts) || Error.raise_link_name_error(matching_link_types, base_component, dep_component, opts)
      end

      def self.component_object?(user_friendly_name, assembly_instance)
        begin 
          Component.name_to_object(assembly_instance.model_handle(:component), user_friendly_name, assembly_id: assembly_instance.id)
        rescue ErrorNameDoesNotExist
          nil
        end
      end
      
      private
      
      def self.matching_link_types(base_component, dep_component)
        matching_link_defs = LinkDef.get_link_defs_matching_antecendent(base_component, dep_component)
        matching_link_defs.map { |ld| ld.get_field?(:link_type) }.uniq
      end
      # opts can have keys:
      #   :link_name
      def self.unique_link_name?(matching_link_types, opts = {})
        if link_name = opts[:link_name] 
          link_name if matching_link_types.include?(link_name)
        elsif matching_link_types.size == 1
          matching_link_types.first
        end
      end
    
      def self.get_augmented_attribute_links(port_link_idhs)
        ret = []
        return ret if port_link_idhs.empty?
        sp_hash = {
          cols: [:id, :group_id, :port_link_id, :input_id, :output_id, :dangling_link_info],
          filter: [:oneof, :port_link_id, port_link_idhs.map(&:get_id)]
        }
        attribute_link_mh = port_link_idhs.first.createMH(:attribute_link)
        Model.get_objs(attribute_link_mh, sp_hash)
      end
      
    end
  end
end
