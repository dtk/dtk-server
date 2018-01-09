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
  class DependentModule
    Element = Struct.new(:namespace, :module_name, :version)
    
    def initialize(assembly_instance)
      @assembly_instance       = assembly_instance
      @service_instance_branch = assembly_instance.get_service_instance_branch
    end
    private :initialize

    def self.get_dependent_module_refs_array(assembly_instance)
      new(assembly_instance).dependent_module_refs_array
    end

    # aug_dependent_module_branches reflect branch for service instance if created
    def self.get_aug_dependent_module_branches(assembly_instance)
      new(assembly_instance).aug_dependent_module_branches
    end

    # Just matches the base branch, not branch created for service instance
    def self.get_aug_base_module_branches(assembly_instance)
      new(assembly_instance).aug_base_module_branches
    end

    def self.delete_dependent_module_repos?(assembly_instance)
       new(assembly_instance).delete_dependent_module_repos?
    end

    # The version in elements is from the dependencies base branch
    def dependent_module_refs_array
      @dependent_module_refs_array ||= ModuleRef.get_module_ref_array(self.service_instance_branch)
    end
    
    # TODO: DTK-3366 can we use :common_module rather than :component_module
    DEP_MODULE_TYPE = :component_module

    def aug_dependent_module_branches
      matching_module_branches_with_elements(module_type: DEP_MODULE_TYPE, assembly_branch_if_exists: true).map do |r|
        ModuleBranch::Augmented.create(r.module_branch, module_name: r.element.module_name, namespace: r.element.namespace)
      end
    end

    def aug_base_module_branches
      aug_module_branches = matching_module_branches_with_elements(module_type: DEP_MODULE_TYPE).map do |r|
        ModuleBranch::Augmented.create(r.module_branch, module_name: r.element.module_name, namespace: r.element.namespace)
      end
      
      ModuleBranch::Augmented.augment_with_repos!(aug_module_branches)
      ModuleBranch::Augmented.augment_with_component_modules!(aug_module_branches)
      aug_module_branches
    end

    def delete_dependent_module_repos?
      return unless self.service_instance_branch
      matching_aug_modules(module_type: DEP_MODULE_TYPE).each do |aug_module|
        aug_module.delete_version?(self.assembly_branch_name)
      end
    end

    protected
    
    attr_reader :assembly_instance, :service_instance_branch
    
    def elements
      @elements ||= self.dependent_module_refs_array.map { |ref| Element.new(ref[:namespace_info], ref[:module_name], ref.version) }
    end
    
    def namespace_objects
      @namespace_objects ||= get_namespace_objects
    end

    def assembly_branch_name
      @assembly_branch_name ||= ModuleVersion.ret(self.assembly_instance)
    end
    
    private
    
    MatchingBranchInfo = Struct.new(:module_branch, :element, :module)
    # returns array where each element is a MatchingBranchInfo element
    # opts can have keys:
    #   :module_type (default is :common_module)
    #   :assembly_branch_if_exists
    def matching_module_branches_with_elements(opts = {})
      branch_info_array = []
      matching_aug_modules(module_type: opts[:module_type]).each do |aug_module|
        if element = matching_element?(aug_module, assembly_branch_if_exists: opts[:assembly_branch_if_exists]) 
          module_obj = aug_module.hash_subset(:id, :group_id, :display_name, :namespace_id)
          branch_info_array << MatchingBranchInfo.new(aug_module[:module_branch], element,  module_obj)
        end
      end
      prune_when_assembly_branch_exists!(branch_info_array) if opts[:assembly_branch_if_exists]
      branch_info_array
    end
    
    # opts can have keys
    #  :module_type (default is :common_module)
    def matching_aug_modules(opts = {})
      module_type = opts[:module_type] || :common_module
      filter = 
        [:and, 
         [:oneof, :namespace_id, self.namespace_objects.map(&:id)],
         [:oneof, :display_name, self.elements.map(&:module_name).uniq]
        ]
      sp_hash = { 
        cols: [:id, :group_id, :display_name, :namespace_id, :namespace, :version_info],
        filter: filter
      }
      Model.get_objs(model_handle(module_type), sp_hash)
    end

    # opts can have keys:
    #   :assembly_branch_if_exists
    def matching_element?(aug_module, opts = {})
      self.elements.find do |el|
        versions =  [el.version]
        versions << self.assembly_branch_name if opts[:assembly_branch_if_exists]

        el.namespace == aug_module[:namespace].display_name and 
          el.module_name == aug_module.display_name and 
          versions.include?(aug_module[:module_branch][:version])
      end
    end

    def prune_when_assembly_branch_exists!(branch_info_array)
      ndx_by_mod = {}
      branch_info_array.each { |info| (ndx_by_mod[info.module.id] ||= []) << info }
      ndx_by_mod.values.map do |info_array|
        if info_array.size == 1
          info_array.first
        else
          info_array.find { |info| info[:module_branch][:version] == self.assembly_branch_name } || fail(Error, "Unexpected no assembly_branch_name match")
        end
      end
    end

    def get_namespace_objects 
      Namespace.matching_namespaces_from_names(model_handle(:namespace), self.elements.map(&:namespace).uniq)
    end
    
    def model_handle(module_type)
      self.assembly_instance.model_handle(module_type)
    end
  end
end

