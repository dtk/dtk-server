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
    module NodeComponentMixin
      def add_ec2_node_components(project, node, image, instance_size, component_module_refs) 
        add_ec2_properties_and_set_attributes(project, node, image, instance_size, component_module_refs: component_module_refs)
        add_ec2_canonical_node_component(project, node, component_module_refs)
      end

      # opts can have keys:
      #   :component_module_refs
      def add_ec2_properties_and_set_attributes(project, node, image, instance_size, opts = {})
        component_module_refs = opts[:component_module_refs] || get_component_module_refs

        domain_component = Component::Domain::Node::Properties
        cmp_name         = domain_component.ec2_component_display_name_form
        
        new_node_component = add_ec2_component(project, node, cmp_name, component_module_refs, auto_complete_links: true)
        
        node.update_object!(:display_name)
        node_name = node.display_name
        
        service = Service.new(self, components: [new_node_component])
        node = (CommandAndControl.create_nodes_from_service(service)||[]).first
        
        av_pairs = []
        if vpc_images = node.vpc_images
          av_pairs = validate_image_and_size(vpc_images, node_name, image, instance_size)
        end
        set_attributes(av_pairs) unless av_pairs.empty?
        
        node.validate_and_fill_in_values!
      end
      
      private
      
      def add_ec2_canonical_node_component(project, node, component_module_refs)
        domain_component = Component::Domain::Node::Canonical
        cmp_name         = "#{domain_component.ec2_component_display_name_form}[#{node.name}]"
        
        add_ec2_component(project, node, cmp_name, component_module_refs, donot_update_workflow: true)
      end

      # opts can have keys 
      #   :auto_complete_links
      #   :donot_update_workflow
      def add_ec2_component(project, node, component_name, component_module_refs, opts = {})
        component_type = Component.component_type_from_user_friendly_name(component_name)
        aug_component_template = find_matching_aug_component_template(component_type, component_module_refs)
        
        component_title = ComponentTitle.parse_title?(component_name)
        new_component_idh = add_component(node.id_handle, aug_component_template, component_title, Opts.new(opts.merge(project: project)))
        new_component_idh.create_object
      end
      
    end
  end
end
