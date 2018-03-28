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
  class ModuleRef < Model
    require_relative('module_ref/version_info')
    require_relative('module_ref/missing')

    def self.common_columns
      [:id, :display_name, :group_id, :module_name, :module_type, :version_info, :namespace_info, :external_ref, :branch_id]
    end

    def version
      @version ||= get_field?(:version_info) || VERSION_WHEN_VERSION_INFO_NIL
    end
    VERSION_WHEN_VERSION_INFO_NIL = 'master'

    def self.reify(mh, object)
      mr_mh = mh.createMH(:model_ref)
      ret = version_info = nil
      if object.is_a?(ModuleRef)
        ret = object
        version_info = VersionInfo::Assignment.reify?(object)
      else #object.kind_of?(Hash)
        ret = ModuleRef.create_stub(mr_mh, object)
        if v = object[:version_info]
          version_info = VersionInfo::Assignment.reify?(v)
        end
      end
      version_info ? ret.merge(version_info: version_info) : ret
    end

    def set_module_version(version)
      merge!(version_info: VersionInfo::Assignment.reify?(version))
      self
    end

    ModuleRefComponentModulePair = Struct.new(:module_ref, :component_module)
    #returns an array of ModuleRefComponentModulePair objects
    def self.find_module_refs_matching_component_modules(cmp_module_refs)
      ret = []
      return ret if cmp_module_refs.empty?
      sp_hash = {
        cols: [:id, :group_id, :display_name, :namespace_id, :namespace],
        filter: [:or] + cmp_module_refs.map { |r| [:eq, :display_name, r[:module_name]] }
      }
      cmp_modules = get_objs(cmp_module_refs.first.model_handle(:component_module), sp_hash)
      cmp_module_refs.each do |cmr|
        module_name = cmr[:module_name]
        namespace = cmr.namespace
        if cmp_module = cmp_modules.find { |mod| mod[:display_name] == module_name && (mod[:namespace] || {})[:display_name] == namespace }
          ret << ModuleRefComponentModulePair.new(cmr, cmp_module)
        end
      end
      ret
    end

    def self.get_module_ref_array(module_branch)
      sp_hash = {
        cols: common_columns,
        filter: [:eq, :branch_id, module_branch.id]
      }
      get_objs(module_branch.model_handle(:module_ref), sp_hash)
    end

    def self.create_or_update(parent, module_ref_hash_array)
      update(:create_or_update, parent, module_ref_hash_array)
    end

    def self.update(operation, parent, module_ref_hash_array)
      return if module_ref_hash_array.empty? && operation == :add
      rows = ret_create_rows(parent, module_ref_hash_array)
      model_handle = parent.model_handle.create_childMH(:module_ref)
      case operation
       when :create_or_update
        matching_cols = [:module_name]
        modify_children_from_rows(model_handle, parent.id_handle, rows, matching_cols, update_matching: true, convert: true)
       when :add
        create_from_rows(model_handle, rows)
       else
        fail Error.new("Unexpected operation (#{operation})")
      end
    end

    def version_string
      self[:version_info] && self[:version_info].respond_to?(:version_string) && self[:version_info].version_string
    end

    def namespace
      unless self[:namespace_info].nil?
        if self[:namespace_info].is_a?(String)
          self[:namespace_info]
        else
          fail Error.new("Unexpected type in namespace_info: #{self[:namespace_info].class}")
        end
      end
    end

    def module_name
      get_field?(:module_name)
    end

    def dsl_hash_form
      ret = Aux.hash_subset(self, [])
      if namespace = namespace()
        ret.merge!(namespace: namespace)
      end
      if version = version_string
        ret.merge!(version: version)
      end
      ret
    end

    def print_form
      ret = "#{namespace}:#{module_name}"
      if version = version_string
        ret << "(#{version})"
      end
      ret
    end

    private

    def self.ret_create_rows(parent, module_ref_hash_array)
      ret = []
      return ret if module_ref_hash_array.empty?
      parent_id_assigns = {
        parent.parent_id_field_name(:module_ref) => parent.id
      }
      module_ref_hash_array.map do |module_ref_hash|
        el = Aux.hash_subset(module_ref_hash, [:ref, :display_name, :module_name, :module_type, :namespace_info, :external_ref]).merge(parent_id_assigns)
        version_info = module_ref_hash[:version_info]
        el.merge!(version_info: version_info && version_info.to_s)
        el[:display_name] ||= display_name(el)
        el[:ref] ||= ref(el)
        el
      end
    end

    def self.display_name(module_ref_hash)
      [:module_name].each do |key|
        if module_ref_hash[key].nil?
          fail Error.new("Unexpected that module_ref_hash[#{key}] is nil")
        end
      end
      module_ref_hash[:module_name]
    end

    def self.ref(module_ref_hash)
      [:module_type, :module_name].each do |key|
        if module_ref_hash[key].nil?
          fail Error.new("Unexpected that module_ref_hash[#{key}] is nil")
        end
      end
      "#{module_ref_hash[:module_type]}--#{module_ref_hash[:module_name]}"
    end
  end
end
