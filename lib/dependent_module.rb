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
    
    def self.get_aug_base_module_branches(assembly_instance)
      new(assembly_instance).aug_base_module_branches
    end

    def self.delete_assembly_module_branch?(assembly_instance)
       new(assembly_instance).delete_assembly_module_branch?
    end

    # The version in elements is from the dependencies base branch
    def dependent_module_refs_array
      @dependent_module_refs_array ||= ModuleRef.get_component_module_ref_array(self.service_instance_branch)
    end
    
    # TODO: DTK-3366 can we use :common_module rather than :component_module
    DEP_MODULE_TYPE = :component_module
    def aug_base_module_branches
      aug_module_branches = matching_module_branches_with_elements(module_type: DEP_MODULE_TYPE).map do |r|
        ModuleBranch::Augmented.create(r.module_branch, module_name: r.element.module_name, namespace: r.element.namespace)
      end
      
      ModuleBranch::Augmented.augment_with_repos!(aug_module_branches)
      ModuleBranch::Augmented.augment_with_component_modules!(aug_module_branches)
      aug_module_branches
    end

    def delete_assembly_module_branch?
      debugger
      ModuleVersion.ret(self.assembly_instance)

      aug_module_branches = matching_module_branches_with_elements(module_type: :component_module)
      fail 'here'
    end
=begin
      sp_hash = {
        cols: [:id, :group_id, :display_name, :component_id],
        filter: [:eq, :version, self.assembly_module_version]
      }
      component_module_mh = self.assembly_instance.model_handle(:component_module)

      # iterate over any service or component module branch that has been created for the service instance
      Model.get_objs(self.assembly_instance.model_handle(:module_branch), sp_hash).each do |module_branch|
        # if module_branch[:component_id] is nil then this is a service module branch, otherwise it is a component module branch
        if module_branch[:component_id].nil?
          Model.delete_instance(module_branch.id_handle) unless opts[:skip_service_module_branch]
        else
          component_module = component_module_mh.createIDH(id: module_branch[:component_id]).create_object
          component_module.delete_version?(self.assembly_module_version)
        end
      end
    end
=end
    
    protected
    
    attr_reader :assembly_instance, :service_instance_branch
    
    def elements
      @elements ||= self.dependent_module_refs_array.map { |ref| Element.new(ref[:namespace_info], ref[:module_name], ref[:version_info]) }
    end
    
    def namespace_objects
      @namespace_objects ||= get_namespace_objects
    end
    
    private
    
    MatchingBranchInfo = Struct.new(:module_branch, :element, :module)
    # returns array where each element is a MatchingBranchInfo element
    # opts can have keys:
    #   :module_type (default is :common_module)
    def matching_module_branches_with_elements(opts = {})
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
      ret = []
      Model.get_objs(model_handle(module_type), sp_hash).each do |aug_module| 
        if element = matching_element?(aug_module) 
          module_obj = aug_module.hash_subset(:id, :group_id, :display_name, :namespace_id)
          ret << MatchingBranchInfo.new(aug_module[:module_branch], element,  module_obj)
        end
      end
      ret
    end
    
    def matching_element?(aug_module)
      self.elements.find do |el|
        el.namespace == aug_module[:namespace].display_name and 
          el.module_name == aug_module.display_name and 
          el.version == aug_module[:module_branch][:version] 
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

