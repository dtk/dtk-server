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
module DTK; class AssemblyModule
  class Service < self
    require_relative('service/workflow')

    # opts can have keys:
    #  :service_module
    def initialize(assembly, opts = {})
      super(assembly)
      @assembly_template_name = ret_assembly_template_name?(assembly)
      @service_module         = opts[:service_module] || get_service_module(assembly)

      # dynamically computed
      @module_branches = nil
    end
    private :initialize

    def self.get_service_instance_branch(assembly)
      new(assembly).get_service_instance_branch
    end

    def get_service_instance_branch
      module_branches.find { |mb| mb.matches_version?(self.assembly_module_version) }
    end

    # opts can have keys:
    #   :version - version of base branch otherwise base is base_version
    def self.get_service_instance_or_base_branch(assembly, opts = {})
      new(assembly).get_service_instance_or_base_branch(opts)
    end
    def get_service_instance_or_base_branch(opts = {})
      if ret = get_service_instance_branch
        return ret
      end

      version = opts[:version]
      module_branches.find do |mb|
        if version 
           mb.matches_version?(version)
        else
          mb.matches_base_version?
        end
      end
    end

    # opts can have keys
    #   :version - base version
    #   :delete_existing_branch
    def self.get_or_create_module_for_service_instance(assembly, opts = {})
       new(assembly).get_or_create_module_for_service_instance(opts)
    end
    def get_or_create_module_for_service_instance(opts = {})
      if existing_branch = self.service_module.get_module_branch_matching_version(self.assembly_module_version)
        return existing_branch unless opts[:delete_existing_branch]
        # existing_branch.delete_instance
      end
      create_module_for_service_instance(opts)
    end

    # returns a ModuleRepoInfo object
    def self.prepare_for_edit(assembly, modification_type, opts = {})
      modification_type_obj = create_modification_type_object(assembly, modification_type, opts)
      # trapping any error when using prepare for edit
      modification_type_obj.create_and_update_assembly_branch?(trap_error: true)
    end

    def self.finalize_edit(assembly, modification_type, service_module, module_branch, diffs_summary, opts = {})
      modification_type_obj = create_modification_type_object(assembly, modification_type, { service_module: service_module }.merge(opts))
      modification_type_obj.finalize_edit(module_branch, diffs_summary)
    end

    # opts can have keys:
    #   :do_not_raise
    def delete_module?(opts = {})
      service_module = get_service_module(self.assembly_instance, opts)
      return if service_module == false
      service_module.delete_version?(self.assembly_module_version, donot_delete_meta: true)
    end

    protected

    attr_reader :assembly_template_name, :service_module

    def module_branches
      @module_branches ||= self.service_module.get_module_branches
    end

    private

    # Creates a repo, repo branch if needed for service and new module branch and returns module branch
    # opts can have keys
    #   :version - base version
    #   :delete_existing_branch
    def create_module_for_service_instance(opts = {})
      base_version = opts[:version]
      self.service_module.create_new_version(base_version, self.assembly_module_version, delete_existing_branch: opts[:delete_existing_branch])
    end

    def ret_assembly_template_name?(assembly)
      if assembly_template = assembly.get_parent
        assembly_template.get_field?(:display_name)
      else
        assembly_name = assembly.display_name_print_form
        Log.info("Assembly (#{assembly_name}) is not tied to an assembly template")
        nil
      end
    end

    # opts can have keys:
    #  :service_module
    #  :task_action
    def self.create_modification_type_object(assembly, modification_type, opts = {})
      modification_type_class(modification_type).new(assembly, opts)
    end

    def self.modification_type_class(modification_type)
      case modification_type
        when :workflow then Workflow
        else fail ErrorUsage.new("Modification type (#{modification_type}) is not supported")
      end
    end

    # opts can have keys:
    #   :do_not_raise
    def get_service_module(assembly, opts = {})
      unless ret = assembly.get_service_module
        assembly_name = assembly.display_name_print_form
        return false if opts[:do_not_raise]
        fail ErrorUsage.new("Assembly (#{assembly_name}) is not tied to a service")
      end
      ret
    end
  end
end; end
