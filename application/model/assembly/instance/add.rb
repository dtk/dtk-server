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
      module AddMixin

        #### Adding components ######

        # aug_cmp_template is a component template augmented with keys having objects
        # :module_branch
        # :component_module
        # :namespace
        # opts can have
        #  :project 
        #  :idempotent
        #  :donot_update_workflow
        #  :splice_in_delete_action
        #  TODO: ...
        def add_component(node_idh, aug_cmp_template, component_title, opts = {})
          # if node_idh it means we call add component from node context
          # else we call from service instance/workspace and use assembly_wide node
          if node_idh
            # first check that node_idh is directly attached to the assembly instance
            # one reason it may not be is if its a node group member
            sp_hash = {
              cols: [:id, :display_name, :group_id, :ordered_component_ids],
              filter: [:and, [:eq, :id, node_idh.get_id], [:eq, :assembly_id, id]]
            }
            
            unless node = Model.get_obj(model_handle(:node), sp_hash)
              if node_group = is_node_group_member?(node_idh)
                fail ErrorUsage.new("Not implemented: adding a component to a node group member; a component can only be added to the node group (#{node_group[:display_name]}) itself")
              else
                fail ErrorIdInvalid.new(node_idh.get_id, :node)
              end
            end
          else
            node = assembly_wide_node
          end
          
          cmp_instance_idh = nil
          opts.merge!(detail_to_include: [:component_dependencies])
          
          Transaction do
            # add the component
            cmp_instance_idh = node.add_component(aug_cmp_template, opts.merge(component_title: component_title))
            component = cmp_instance_idh.create_object

            # update the module refs
            add_component__update_component_module_refs?(aug_cmp_template[:component_module], aug_cmp_template[:namespace], version: aug_cmp_template[:version])
            
            # recompute the locked module refs
            ModuleRefs::Lock.create_or_update(self)
            
            # unless opts[:donot_update_workflow]
            #  Task::Template::ConfigComponents.update_when_added_component_or_action?(self, node, component, component_title: component_title, skip_if_not_found: true)
            # end
            # TODO: DTK-2680: Aldin: for below see if we can simplify with above
            # TODO: DTK-2680: Rich: We will be able to simplify below with above after we change dtk-server/lib/common_dsl/object_logic/assembly/node/diff/delete.rb:90
            # where we add ec2::node[node_name].delete component action to workflow; we can change that to use TaskTemplate.insert_explict_delete_action?(assembly_instance, component, node, force_delete: opts[:force_delete])
            # which we use for other components
            unless opts[:donot_update_workflow]
              update_opts = { skip_if_not_found: true }
              if opts[:splice_in_delete_action]
                cmp_instance = Component::Instance.create_from_component(component)
                action_def = cmp_instance.get_action_def?('delete')
                update_opts.merge!(:action_def => action_def)
              end
              if component_title
                update_opts[:component_title] = component_title
                opts[:component_title] = component_title
              end
              Task::Template::ConfigComponents.update_when_added_component_or_action?(self, node, component, update_opts)
            end

            if opts[:auto_complete_links]
              LinkDef::AutoComplete.autocomplete_component_links(self, components: [component])
            end
          end
          
          cmp_instance_idh
        end

        #### end: Adding components ######

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
        private

        # opts can have keys:
        #  :version
        def add_component__update_component_module_refs?(component_module, namespace, opts = {})
          # TODO: should below instead be get_service_instance_branch
          service_instance_branch = AssemblyModule::Service.get_or_create_module_for_service_instance(self, opts)
          service_instance_branch.set_dsl_parsed!(true)
          component_module_refs = ModuleRefs.get_component_module_refs(service_instance_branch)
          
          # TODO: not sure if the best way to handle using different version of component module
          # unless we delete existing it will not update if version is changed
          cmp_modules = component_module_refs.component_modules
          cmp_modules.delete(component_module[:display_name].to_sym)
          
          version_info = nil if version_info == 'master'
          cmp_modules_with_namespaces = component_module.merge(namespace_name: namespace[:display_name], version_info: version_info)
          if update_needed = component_module_refs.update_object_if_needed!([cmp_modules_with_namespaces])
            # This saves teh upadte to the object model
            component_module_refs.update
          end
        end

      end
    end
  end
end
