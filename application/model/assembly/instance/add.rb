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
  class Assembly
    class Instance
      # methods that add objects (e.g., nodes, components to assembly instance)
      module Add
        require_relative('add/component')
        module Mixin
          include Component::Mixin
          # TODO: put add node and node group in seperate files like we did for component

          #### Adding nodes ######
          def add_node_from_diff(node_name)
            target = get_target
            node_template = Node::Template.find_matching_node_template(target)
            
            override_attrs = {
              display_name: node_name,
              assembly_id: id
            }
            target.clone_into(node_template, override_attrs, node_template.source_clone_info_opts)
          end
          
          def add_node_group_diff(node_group_name, cardinality)
            target = get_target
            node_template = Node::Template.find_matching_node_template(target)
            
            self.update_object!(:display_name)
            ref = SQL::ColRef.concat('assembly--', "#{self[:display_name]}--#{node_group_name}")
            
            override_attrs = {
              display_name: node_group_name,
              assembly_id: id,
              type: 'node_group_staged',
              ref: ref
            }
            
            new_obj = target.clone_into(node_template, override_attrs, node_template.source_clone_info_opts)
            Node::NodeAttribute.create_or_set_attributes?([new_obj], :cardinality, cardinality)
            
            node_group_obj = new_obj.create_obj_optional_subclass
            node_group_obj.add_group_members(cardinality.to_i)
            
            new_obj
          end
          
          def add_node(node_name, node_binding_rs = nil, opts = {})
            # if assembly_wide node (used to add component directly on service_instance/assembly_template/workspace)
            # check if type = Node::Type::Node.assembly_wide
            # or check by name if regular node
            check = opts[:assembly_wide] ? [:eq, :type, Node::Type::Node.assembly_wide] : [:eq, :display_name, node_name]
            
            # check if node has been added already
            if get_node?(check)
              fail ErrorUsage.new("Node (#{node_name}) already belongs to #{pp_object_type} (#{get_field?(:display_name)})")
            end
            
            target = get_target
            node_template = Node::Template.find_matching_node_template(target, node_binding_ruleset: node_binding_rs)
            
            override_attrs = {
              display_name: node_name,
              assembly_id: id
            }
            override_attrs.merge!(type: 'assembly_wide') if opts[:assembly_wide]
            clone_opts = node_template.source_clone_info_opts
            new_obj = target.clone_into(node_template, override_attrs, clone_opts)
            new_obj
          end
          
          def assembly_wide_node
            sp_hash = {
              cols: [:id, :display_name, :group_id, :ordered_component_ids],
              filter: [:and, [:eq, :type, Node::Type::Node.assembly_wide], [:eq, :assembly_id, id]]
            }
            unless node = Model.get_obj(model_handle(:node), sp_hash)
              node_idh = add_node('assembly_wide', nil, assembly_wide: true)
              node = node_idh.is_a?(Node) ? node_idh : node_idh.create_object
            end
            node
          end
          
          #### end: Adding nodes ######
          
          #### Adding node groups ######
          def add_node_group(node_group_name, node_binding_rs, cardinality)
            # check if node has been added already
            if get_node?([:eq, :display_name, node_group_name])
              fail ErrorUsage.new("Node (#{node_group_name}) already belongs to #{pp_object_type} (#{get_field?(:display_name)})")
            end
            
            target = get_target
            node_template = Node::Template.find_matching_node_template(target, node_binding_ruleset: node_binding_rs)
            
            self.update_object!(:display_name)
            ref = SQL::ColRef.concat('assembly--', "#{self[:display_name]}--#{node_group_name}")
          
            override_attrs = {
              display_name: node_group_name,
              assembly_id: id,
              type: 'node_group_staged',
              ref: ref
            }
            
            clone_opts = node_template.source_clone_info_opts
            new_obj = target.clone_into(node_template, override_attrs, clone_opts)
            Node::NodeAttribute.create_or_set_attributes?([new_obj], :cardinality, cardinality)
            
            node_group_obj = new_obj.create_obj_optional_subclass
            node_group_obj.add_group_members(cardinality.to_i)
            
            # TODO: for some reason, node group members targets are populated with wrong target id; fixing that here
            node_group_members = node_group_obj.get_node_group_members
            node_group_members.each do |ng_member|
              ng_member.update(datacenter_datacenter_id: target[:id])
            end
            
            new_obj
          end
          #### end: Adding node groups ######        
        end
      end
    end
  end
end
