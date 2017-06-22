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
  class Service
    # Class for target service instances
    # Wraps older objectsL DTK::Assembly::Instance and DTK::Target
    # TODO: DTK-2489: after we move everything off of DTK::Target we can remove this class or make it
    # a very simple root abstract class
    class Target < self
      require_relative('target/node_template')
      include NodeTemplateMixin

      # opts can have keys
      #  :target
      #  :components
      def initialize(target_assembly_instance, opts = {})
        super(target_assembly_instance, components: opts[:components])
        @target = opts[:target] || target_assembly_instance.get_target
      end
      private :initialize

      def self.create_from_node(node)
        create_from_target(node.get_target)
      end

      # Creates a Service::Target object 
      # opts can have keys
      #  :components
      def self.create_from_assembly_instance?(assembly_instance, opts = {})
        # TODO: DTK-3076: removed check if isa_target_assembly_instance?(assembly_instance)
        #       This alows staging with respect to any service instance. we still need to have dtk service list'
        #       display right by adding a field to component table that has service_parent_id and using that rather than
        #       target name. Also need to clean up and remove descrete logic categorizing target or not target
        #       and related default target logic
        new(assembly_instance, components: opts[:components]) 
      end

      # This function is used to help bridge between using targets and service instances
      # There are places in code where target is referenced, but we want to get a handle on a service isnatnce that has
      def self.create_from_target(target)
        new(find_assembly_instance_from_target(target), target: target)
      end

      ###### Just called from v1 controller ######
      # This method stages a target service
      # opts can have keys
      #   :project (required)
      #   :target_name (required)
      #   :service_module
      #   :service_name
      #   :no_auto_complete - Boolean (default: false)
      #   :add_nested_modules - Boolean (default: false)
      def self.stage_target_service(assembly_template, service_module_class, opts = Opts.new)
        Model.Transaction do
          target = create_target_mock(opts[:target_name], opts[:project])
          stage_opts = common_stage_opts.merge(is_target_service: true).merge(opts)
          new_assembly_instance = assembly_template.stage(target, stage_opts)
          fixup_target_name_and_ref!(new_assembly_instance, target)
          module_repo_info = service_module_class.create_service_instance_and_nested_modules(new_assembly_instance, opts)
          Aux.stop_for_testing?(:stage)
          new_service_info(new_assembly_instance, module_repo_info)
        end
      end

      # The method stage_service stages the assembly_template wrt this, which is a target service instance
      # opts can have keys
      #   :project
      #   :service_module
      #   :service_name
      #   :no_auto_complete - Boolean (default: false)
      #   :allow_existing_service - Boolean (default: false)
      #   :add_nested_modules - Boolean (default: false)
      def stage_service(assembly_template, service_module_class, opts = Opts.new)
        unless is_converged? 
          fail ErrorUsage, "Cannot stage a service instance in a target service instance '#{target}' that is not converged."
        end
        Model.Transaction do
          # if :allow_existing_service is true then new_assembly_instance can be existing assembly_instance
          stage_opts = common_stage_opts.merge(is_target_service: false, parent_service_instance: @assembly_instance).merge(opts)
          new_assembly_instance = assembly_template.stage(target, stage_opts)
          module_repo_info = service_module_class.create_service_instance_and_nested_modules(new_assembly_instance, opts)
          Aux.stop_for_testing?(:stage) 
          self.class.new_service_info(new_assembly_instance, module_repo_info)
        end
      end

      private

      def self.common_stage_opts
        Opts.new(donot_create_modules: true)
      end
      def common_stage_opts
        self.class.common_stage_opts
      end

      ###### end: Just called from v1 controller ######

      public

      def target
        Log.error("Unexpected that @target is nil") unless @target
        @target
      end

      def display_name
        @assembly_instance.display_name
      end

      def self.target_when_target_assembly_instance?(assembly)
        assembly.copy_as_assembly_instance.get_target() if isa_target_assembly_instance?(assembly)
      end

      def is_converged?
        if status = @assembly_instance && @assembly_instance.get_last_task_run_status?
          status == 'succeeded'
        end
      end

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

      private

      def self.isa_target_assembly_instance?(assembly_instance)
        if specific_type = assembly_instance.get_field?(:specific_type)
          specific_type.eql?('target')
        end
      end

      def self.find_assembly_instance_from_target(target)
        # Assumption that target name and assembly instance that corresponds to target have the same name
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:and, 
                   [:eq, :datacenter_datacenter_id, target.id],
                   [:eq, :display_name, target.get_field?(:display_name)]]
        }
        unless ret = Assembly::Instance.get_obj(target.model_handle(:assembly_instance), sp_hash)
          Log.error("Unexpected that find_assembly_instance_from_target returns nil")
        end
        ret
      end

      def self.new_service_info(assembly_instance, module_repo_info)
        {
          service: {
            name: assembly_instance.display_name_print_form,
            id: assembly_instance.id
          }
        }.merge(module_repo_info)
      end

      def self.fixup_target_name_and_ref!(assembly_instance, target)
        display_name = assembly_instance.get_field?(:display_name)
        ref          = display_name.downcase.gsub(/ /, '-')
        target.update(display_name: display_name, ref: ref)
      end
    end
  end
end
