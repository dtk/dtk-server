
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
    class Stage
      require_relative('stage/custom_node_attributes')
      require_relative('stage/assembly_attribute_links')
      module Mixin
        # opts can have keys:
        #  :service_module - service module object
        #  :context_assembly_instances
        #  :project
        #  :service_settings - TODO: may be deprecated
        #  :node_size
        #  :os_type
        #  :no_auto_complete - Boolean (default false)
        #  :ret_auto_complete_results:
        #  :donot_create_modules
        def stage(service_name, opts = Opts.new)
          Stage.new(self, service_name, opts).stage
        end
      end

      def initialize(assembly_template, service_name, opts = Opts.new)
        @assembly_template            = assembly_template
        @service_name                 = service_name
        @project                      = opts[:project] || fail(Error.new, "Unexpected that opts[:project] is nil")
        @version                      = opts[:version]
        @context_assembly_instances   = opts[:context_assembly_instances] || []
        @opts                         = opts
        @donot_create_modules         = opts[:donot_create_modules]
        @no_auto_complete             = opts[:no_auto_complete]
        @ret_auto_complete_results    = opts[:ret_auto_complete_results]
      end
      
      def stage
        fail_if_module_unparsed

        fail_if_a_context_is_not_converged
        
        assembly_instance = nil
        Model.Transaction do
          assembly_instance = clone_assembly_template

          add_context_assembly_instances(assembly_instance)
          create_nested_modules(assembly_instance) unless self.donot_create_modules
          # create_module_ref_shas needs to be done after create_nested_modules
          create_module_ref_shas(assembly_instance)

          add_custom_node_attributes?(assembly_instance)
        end
        
        # TODO: see if below should also be inside Transaction

        # autocomplete_component_links needs to be called after add_context_assembly_instances
        # autocomplete_results is of type LinkDef::AutoComplete::Results
        autocomplete_results = nil
        unless self.no_auto_complete
          auto_complete_results = LinkDef::AutoComplete.autocomplete_component_links(assembly_instance)
        end

        AssemblyAttributeLinks.add(assembly_instance)

        fixup_target_name_and_ref(assembly_instance)
        if self.ret_auto_complete_results 
          [assembly_instance, auto_complete_results]
        else
          assembly_instance
        end
      end
      
      protected
      
      attr_reader :assembly_template, :service_name, :project, :version, :context_assembly_instances, :donot_create_modules, :no_auto_complete, :ret_auto_complete_results, :opts
      
      def target
        @target ||= create_target_mock
      end
      
      def service_module
        @service_module  ||= self.opts[:service_module] || self.assembly_template.get_service_module
      end
      
      def service_module_branch
        @service_module_branch ||= ret_service_module_branch
      end
      
      def override_attrs
        @override_attrs || ret_override_attrs
      end
      
      def clone_opts
        @clone_opts || ret_clone_opts
      end
      
      private

      def fail_if_module_unparsed
        fail ErrorUsage, "An assembly template from an unparsed module '#{self.service_module.display_name}' cannot be staged" unless self.service_module_branch.dsl_parsed?
      end

      def fail_if_a_context_is_not_converged
        self.context_assembly_instances.each do |context_assembly_instance|
          unless is_converged?(context_assembly_instance) 
            context_name = context_assembly_instance.display_name
            fail ErrorUsage, "Cannot stage a service instance with respect to a context service instance '#{context_name}' that is not converged."
          end
        end
      end

      def is_converged?(assembly_instance)
        status = assembly_instance.get_last_task_run_status?
        # The condition status.nil? means that no workflow which it implies that it is params only assembly_instance
        status.nil? or status == 'succeeded'
      end

      # Returns the newly created assembly_instance 
      def clone_assembly_template
        new_assembly_obj  = self.target.clone_into(self.assembly_template, self.override_attrs, self.clone_opts)
        assembly_instance = Assembly::Instance.create_subclass_object(new_assembly_obj)
      end

      def create_module_ref_shas(assembly_instance)
        assembly_instance.create_module_ref_shas(self.service_module, version: self.version)
      end

      def create_nested_modules(assembly_instance)
        AssemblyModule::Service.get_or_create_module_for_service_instance(assembly_instance, version: self.version) 
      end

      def add_custom_node_attributes?(assembly_instance)
        CustomNodeAttributes.set_if_needed(assembly_instance, node_size: self.opts[:node_size], os_type: self.opts[:os_type])
      end

      def add_context_assembly_instances(assembly_instance)
        self.context_assembly_instances.each do |context_assembly_instance|
          ServiceAssociations.create_associations(self.project, assembly_instance, context_assembly_instance)
        end
      end

      def ret_service_module_branch
        self.version ? self.service_module.get_module_branch_matching_version(self.version) : self.service_module.get_workspace_module_branch
      end

      def ret_override_attrs
        # including :description here because it is not a field that gets copied by clone copy processor
        override_attrs = { 
          display_name:  self.service_name,
          description: self.assembly_template.get_field?(:description), 
          service_module_sha: self.service_module_branch[:current_sha] 
        }
        override_attrs.merge!(specific_type: 'target') if is_base_service?
        override_attrs
      end 

      def is_base_service?
        self.context_assembly_instances.empty?
      end

      def ret_clone_opts
        clone_opts = { ret_new_obj_with_cols: [:id, :type] }
        if settings = self.opts[:service_settings]
          clone_opts.merge!(service_settings: settings)
        end
        
        if self.version
          clone_opts.merge!(version: self.version) unless self.version.eql?('master')
        end
        clone_opts
      end

      # TODO: this is hack that shouud be fixed up so not ec2 specfic
      def create_target_mock
        ref = self.service_name.downcase.gsub(/ /, '-')
        create_row = {
          ref: ref,
          display_name: self.service_name,
          type: 'instance',
          iaas_type: 'ec2',
          iaas_properties: {},
          project_id: self.project.id
        }
        Model.create_from_row(self.project.model_handle(:target), create_row, convert: true, ret_obj: { model_name: :target_instance })
      end
      
      def fixup_target_name_and_ref(assembly_instance)
        display_name = assembly_instance.display_name
        ref          = display_name.downcase.gsub(/ /, '-')
        self.target.update(display_name: display_name, ref: ref)
        self.target
      end

      # ---- end hack
    end
  end
end
