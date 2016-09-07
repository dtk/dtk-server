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
    r8_nested_require('service', 'workflow')

    def initialize(assembly, opts = {})
      super(assembly)
      @assembly_template_name = assembly_template_name?(assembly)
      @service_module = opts[:service_module] || get_service_module(assembly)
      @am_version = assembly_module_version(assembly)
    end
    private :initialize

    # TODO: DTK-2650; Aldin: think that get_assembly_branch should not have opts; assembly has all the info it needs to determien branch
    # This checks if an assembly specfic branch has been made and returns this otherwise gives the base branch
    def self.get_assembly_branch(assembly, opts = {})
      new(assembly).get_assembly_branch(opts)
    end
    def get_assembly_branch(opts = {})
      module_branches = @service_module.get_module_branches
      # TODO: DTK-2650; commented out below; problem is that find can match multiple cases so non determinstmn; so changed to do what I think only match should be

      if ret = module_branches.find { |mb| mb.matches_version?(@am_version) }
        return ret
      end

      # TODO: DTK-2650; dont think we want to have opts (and match againts opts) see if we need match with base version
      # put in these two matches, but they shoudl be looked at to see what shoudl be taken out
      module_branches.find do |mb|
        mb.matches_version?(opts[:version]) || mb.matches_base_version?
      end

      # TODO: DTK-2650: commented out
      # module_branches.find { |mb| mb.matches_version?(@am_version) } || module_branches.find(&:matches_base_version?)
      # module_branches.find do |mb|
      #  return mb if mb.matches_version?(@am_version) || mb.matches_version?(opts[:version]) || mb.matches_base_version?
      # end
    end

    def self.get_or_create_assembly_branch(assembly)
       new(assembly).get_or_create_assembly_branch()
    end
    def get_or_create_assembly_branch(opts = {})
      @service_module.get_module_branch_matching_version(@am_version) || create_assembly_branch(opts)
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

    def delete_module?(opts = {})
      service_module = get_service_module(@assembly, opts)
      return if service_module == false
      am_version = assembly_module_version()
      service_module.delete_version?(am_version, donot_delete_meta: true)
    end

    private

    # returns new module branch
    def create_assembly_branch(opts = {})
      base_version = @service_module.get_field?(:version) || opts[:version] #TODO: is this right; shouldnt version be on branch, not module
      @service_module.create_new_version(base_version, @am_version)
    end

    def assembly_template_name?(assembly)
      if assembly_template = assembly.get_parent()
        assembly_template.get_field?(:display_name)
      else
        assembly_name = assembly.display_name_print_form()
        Log.info("Assembly (#{assembly_name}) is not tied to an assembly template")
        nil
      end
    end

    def self.create_modification_type_object(assembly, modification_type, opts = {})
      modification_type_class(modification_type).new(assembly, opts)
    end

    def self.modification_type_class(modification_type)
      case modification_type
        when :workflow then Workflow
        else fail ErrorUsage.new("Modification type (#{modification_type}) is not supported")
      end
    end

    def get_service_module(assembly, opts = {})
      unless ret = assembly.get_service_module()
        assembly_name = assembly.display_name_print_form()
        return false if opts[:do_not_raise]
        fail ErrorUsage.new("Assembly (#{assembly_name}) is not tied to a service")
      end
      ret
    end
  end
end; end
