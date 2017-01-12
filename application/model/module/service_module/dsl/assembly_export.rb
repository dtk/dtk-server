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
  class ServiceModule
    class AssemblyExport < Hash
      require_relative('assembly_export/fold_into_existing')

      include ServiceDSLCommonMixin

      def initialize(factory, container_idh, service_module_branch, integer_version)
        super()
        @container_idh = container_idh
        @service_module_branch = service_module_branch
        @integer_version = integer_version
        @factory = factory
        @serialized_assembly_file = nil
      end
      private :initialize

      attr_reader :factory
      def self.create(factory, container_idh, service_module_branch, integer_version = nil)
        integer_version ||= DSLVersionInfo.default_integer_version()
        klass = load_and_return_version_adapter_class(integer_version)
        klass.new(factory, container_idh, service_module_branch, integer_version)
      end

      def save_to_model
        Model.input_hash_content_into_model(@container_idh, self, preserve_input_hash: true)
      end

      def serialize_and_save_to_repo?(opts = {})
        assembly_dsl_path = assembly_meta_filename_path()
        serialized_content = serialize()

        # if assembly part has assembly level components and nodes, make sure components are always in the first place
        if assembly = serialized_content[:assembly]
          if assembly.has_key?(:components) && !assembly.keys.first.to_s.eql?('components')
            assembly.keys.each do |key|
              assembly.merge!(key => assembly.delete(key)) unless key.to_s.eql?('components')
            end
          end
        end

        # when create assembly we don't want to store ec2::properties component in assembly.yaml
        # will store ec2::properties attributes as node attributes instead
        check_for_ec2_attributes(serialized_content)

        # Check to determine whether shoudl generate assembly_dsl_path from serialized_content (from fresh)
        # or whether it should use existing file to keep context like comments, spacing
        # it should only use existing file as part of this if
        # - this is an update (rather than a create operation)
        # - serialized_content has an assembly section
        # - the file 'assembly_dsl_path' exists
        new_commit_sha = nil
        if opts[:mode] == :update and
            serialized_content_has_assembly_section?(serialized_content) and
            file_exists?(assembly_dsl_path)
            new_commit_sha = serialize_and_save_to_repo__fold_into_existing?(assembly_dsl_path, serialized_content)
        else
          new_commit_sha = serialize_and_save_to_repo__fresh?(assembly_dsl_path, serialized_content)
        end

        @factory.assembly_instance.update_from_hash_assignments(:service_module_sha => new_commit_sha) if new_commit_sha
        assembly_dsl_path
      end

      # if any messages to pass end user, this will return a string with the merge_message
      def merge_conflicts?(assembly_instance)
        ret = nil
        assembly_dsl_path = assembly_meta_filename_path()
        return ret unless file_exists?(assembly_dsl_path)

        initial_sha = assembly_instance.get_field?(:service_module_sha)
        current_sha = @service_module_branch[:current_sha]
        return ret if initial_sha.eql?(current_sha)

        unless instance_lock = Assembly::Instance::Lock.get(assembly_instance)
          Log.info('Legacy can have Assembly::Instance::Lock.get(assembly_instance) be nil')
          return ret
        end

        service_instance_branch = assembly_instance.get_service_instance_branch
        assembly_instance_latest_change = service_instance_branch ? service_instance_branch.get_field?(:updated_at) : (assembly_instance.get_field?(:updated_at) || assembly_instance.get_field?(:created_at))

        return ret unless file_changed_since_specified_sha(initial_sha, assembly_dsl_path, instance_lock, assembly_instance_latest_change)

        # move current assembly.yaml and create new one; also notify user
        destination_name = "#{assembly_dsl_path}.dtk-backup"
        RepoManager.move_file(assembly_dsl_path, destination_name, @service_module_branch)

        "New #{assembly_dsl_path} is generated from service instance content because we were not able to merge with existing one. Backup of old file has been stored at #{destination_name} so you can merge manually or you can delete backup files."
      end

      private

      def file_changed_since_specified_sha(initial_sha, assembly_dsl_path, instance_lock, assembly_instance_latest_change)
        service_module_sha_timestamp = @service_module_branch.get_field?(:updated_at)
        instance_lock_sha_timestamp  = instance_lock[:created_at]

        if service_module_sha_timestamp && instance_lock_sha_timestamp
          return if service_module_sha_timestamp.to_i <= instance_lock_sha_timestamp.to_i
        end

        RepoManager.file_changed_since_specified_sha(initial_sha, assembly_dsl_path, @service_module_branch)
      end

      def file_exists?(path)
        RepoManager.file_exists?(path, @service_module_branch)
      end

      def serialized_content_has_assembly_section?(serialized_content)
        !(serialized_content[:assembly] || {})[:nodes].nil?
      end

      # returns new_commit_sha if no commit; else nil
      def serialize_and_save_to_repo__fresh?(assembly_dsl_path, serialized_content)
        @service_module_branch.serialize_and_save_to_repo?(assembly_dsl_path, serialized_content)
      end

      # returns new_commit_sha if no commit; else nil
      def serialize_and_save_to_repo__fold_into_existing?(assembly_dsl_path, serialized_content)
        begin
          @serialized_assembly_file ||= fold_into_existing_assembly_dsl(assembly_dsl_path, serialized_content)
          commit_msg = "Update to assembly template with path #{assembly_dsl_path}"
          @service_module_branch.save_file_content_to_repo?(assembly_dsl_path, @serialized_assembly_file, commit_msg: commit_msg)
         rescue => e
          #In case any error in routine to incrementally fold in to assembly we will just generate from new content (i.e., from fresh)
          Log.error_pp([e])
          serialize_and_save_to_repo__fresh?(assembly_dsl_path, serialized_content)
        end
      end

      # returns new_commit_sha if no commit; else nil
      def fold_into_existing_assembly_dsl(assembly_dsl_path, serialized_content)
        raw_content_existing = @service_module_branch.get_raw_file_content(assembly_dsl_path)
        FoldIntoExisting.fold_into_existing_assembly_dsl(raw_content_existing, serialized_content)
      end

      def self.load_and_return_version_adapter_class(integer_version)
        return CachedAdapterClasses[integer_version] if CachedAdapterClasses[integer_version]
        adapter_name = "v#{integer_version}"
        opts = {
          class_name: { adapter_type: 'AssemblyExport' },
          subclass_adapter_name: true,
          base_class: ServiceModule
        }
        CachedAdapterClasses[integer_version] = DynamicLoader.load_and_return_adapter_class('assembly_export', adapter_name, opts)
      end
      CachedAdapterClasses = {}

      def assembly_meta_filename_path
        ServiceModule.assembly_meta_filename_path(assembly_hash()[:display_name], @service_module_branch)
      end

      def assembly_hash
        self[:component].values.first
      end

      def dsl_version?
        ServiceModule::DSLVersionInfo.integer_version_to_version(@integer_version)
      end

      def assembly_description?
        # @factory.assembly_instance.get_field?(:description)
        @factory[:description] || @factory[:display_name]
      end

      def component_output_form(component_hash)
        name = component_name_output_form(component_hash[:display_name])
        if attr_overrides = component_hash[:attribute_override]
          { name => attr_overrides_output_form(attr_overrides) }
        else
          name
        end
      end

      def component_name_output_form(internal_format)
        internal_format.gsub(/__/, Seperators[:module_component])
      end

      def check_for_ec2_attributes(serialized_content)
        assembly = serialized_content[:assembly]
        if assembly_nodes = assembly && assembly[:nodes]
          use_ec2_properties_as_node_attributes(assembly_nodes)
        end
      end

      def use_ec2_properties_as_node_attributes(assembly_nodes)
        assembly_nodes.each_pair do |node_name, node_content|
          node_attributes = node_content[:attributes]
          if node_components = node_content[:components]
            node_components = node_components.is_a?(Array) ? node_components : [node_components]
            if index = includes_property_component?(node_components)
              ec2_properties = node_components.delete_at(index)[CommandAndControl.node_property_component()]
              if ec2_attributes = ec2_attributes.is_a?(Hash) && ec2_properties[:attributes]
                if node_attributes
                  node_attributes.merge!(ec2_attributes)
                else
                  node_content[:attributes] = ec2_attributes
                end
              end
            end
          end
        end
      end

      def includes_property_component?(components)
        property_component = CommandAndControl.node_property_component()
        components.each do |component|
          if component.is_a?(Hash)
            return components.index(component) if component.keys.first.eql?(property_component)
          else
            return components.index(component)  if component.eql?(property_component)
          end
        end

        false
      end
    end
  end
end
