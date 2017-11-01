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
  class Assembly::Template
    module Stage
      module Mixin
        # opts can have keys:
        #  :service_module - service module object
        #  :context_assembly_instances
        #  :project
        #  :service_settings - TODO: may be deprecated
        #  :node_size
        #  :os_type
        #  :no_auto_complete - Boolean (default false)
        #  :service_name_globally_scoped - Boolean (default false); alternative is unique wrt to target
        #  :donot_create_modules
        #  :allow_existing_service - Boolean (default false)
        #  TODO: see if any other keys used when passing opts to get_augmented_components(opts) 
        def stage(service_name, opts = Opts.new)
          service_module  = opts[:service_module] || get_service_module
          is_base_service = (opts[:context_assembly_instances] || []).empty? 
          target          =  Stage.create_target_mock(service_name, opts[:project])          

          service_module_branch =
            if version = opts[:version]
              service_module.get_module_branch_matching_version(version)
            else
              service_module.get_workspace_module_branch
            end
          
          # service_module_branch = service_module.get_workspace_module_branch
          unless is_dsl_parsed = service_module_branch.dsl_parsed?
            fail ErrorUsage.new("An assembly template from an unparsed service-module '#{service_module}' cannot be staged")
          end
          
          # including :description here because it is not a field that gets copied by clone copy processor
          override_attrs = { description: get_field?(:description), service_module_sha: service_module_branch[:current_sha] }
          
          # See if service instance name is passed and if so make sure name not used already
          if existing_assembly_instance = Assembly::Instance.exists?(target.model_handle, service_name)
            return existing_assembly_instance if opts[:allow_existing_service]
            fail ErrorUsage.new("Service '#{service_name}' already exists") 
          end
          override_attrs[:display_name] = service_name
          
          override_attrs[:specific_type] = 'target' if is_base_service
          
          clone_opts = { ret_new_obj_with_cols: [:id, :type] }
          if settings = opts[:service_settings]
            clone_opts.merge!(service_settings: settings)
          end
          
          if version = opts[:version]
            clone_opts.merge!(version: version) unless version.eql?('master')
          end
          
          new_assembly_obj  = nil
          assembly_instance = nil
          
          Transaction do
            new_assembly_obj        = target.clone_into(self, override_attrs, clone_opts)
            assembly_instance      = Assembly::Instance.create_subclass_object(new_assembly_obj)
            assembly_instance_lock = Assembly::Instance::Lock.create_from_element(assembly_instance, service_module, opts)
            assembly_instance_lock.save_to_model
            
            AssemblyModule::Service.get_or_create_module_for_service_instance(assembly_instance, version: version) unless opts[:donot_create_modules]
            
            # user can provide custom node-size and os-type attribute, we proccess them here and assign to nodes
            set_custom_node_attributes(assembly_instance, opts) if opts[:node_size] || opts[:os_type]
          end
          
          if context_assembly_instances = opts[:context_assembly_instances]
            ServiceAssociations.create_associations(opts[:project], assembly_instance, context_assembly_instances)
          end
          
          # assumed that service associations set before calling LinkDef::AutoComplete.autocomplete_component_links
          LinkDef::AutoComplete.autocomplete_component_links(assembly_instance) unless opts[:no_auto_complete]
          add_attribute_links(assembly_instance)
          Stage.fixup_target_name_and_ref!(assembly_instance, target)
          assembly_instance
        end
      end

      # TODO: this is hack that shouud be fixed up so not ec2 specfic
      def self.create_target_mock(target_name, project)
        ref = target_name.downcase.gsub(/ /, '-')
        create_row = {
          ref: ref,
          display_name: target_name,
          type: 'instance',
          iaas_type: 'ec2',
          iaas_properties: {},
          project_id: project.id
        }
        create_opts = { convert: true, ret_obj: { model_name: :target_instance } }
        Model.create_from_row(project.model_handle(:target), create_row, create_opts)
      end

      def self.fixup_target_name_and_ref!(assembly_instance, target)
        display_name = assembly_instance.get_field?(:display_name)
        ref          = display_name.downcase.gsub(/ /, '-')
        target.update(display_name: display_name, ref: ref)
      end

      # ---- end hack

    end
  end
end
