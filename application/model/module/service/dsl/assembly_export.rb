module DTK
  class ServiceModule
    class AssemblyExport < Hash
      r8_nested_require('assembly_export', 'fold_into_existing')

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

        # Check to determine whether shoudl generate assembly_dsl_path from serialized_content (from fresh)
        # or whether it should use existing file to keep context like comments, spacing
        # it should only use existing file as part of this if
        # - this is an update (rather than a create operation)
        # - serialized_content has an assembly section
        # - the file 'assembly_dsl_path' exists
        if opts[:mode] == :update and 
            serialized_content_has_assembly_section?(serialized_content) and
            file_exists?(assembly_dsl_path)
          serialize_and_save_to_repo__fold_into_existing?(assembly_dsl_path, serialized_content)
        else
          serialize_and_save_to_repo__fresh?(assembly_dsl_path, serialized_content)
        end

        assembly_dsl_path
      end

      def check_merge_conflicts(assembly_instance)
        assembly_dsl_path = assembly_meta_filename_path()
        return unless file_exists?(assembly_dsl_path)

        initial_sha = assembly_instance.get_field?(:service_module_sha)
        current_sha = @service_module_branch[:current_sha]

        return if initial_sha.eql?(current_sha)

        return unless RepoManager.file_changed_since_specified_sha(initial_sha, assembly_dsl_path, @service_module_branch)

        # move current assembly.yaml and create new one; also notify user

        # TODO: DTK-2208 Aldin: think if there is merge conflict then dont fold into existing file structure
        # Commented out the call that was there (which has method name change to reflect refactoring)
        # this should be double checked to see if this is right
        #  @serialized_assembly_file = fold_into_existing_assembly_dsl(assembly_dsl_path, serialize())

        destination_name = "#{assembly_dsl_path}.dtk-backup"
        RepoManager.move_file(assembly_dsl_path, destination_name, @service_module_branch)

        "New #{assembly_dsl_path} is generated from service instance content because we were not able to merge with existing one. Backup of old file has been stored at #{destination_name} so you can merge manually or you can delete backup files."
      end

      private
      
      def file_exists?(path)
        RepoManager.file_exists?(path, @service_module_branch)
      end

      def serialized_content_has_assembly_section?(serialized_content)
        !(serialized_content[:assembly] || {})[:nodes].nil?
      end

      def serialize_and_save_to_repo__fresh?(assembly_dsl_path, serialized_content)
        @service_module_branch.serialize_and_save_to_repo?(assembly_dsl_path, serialized_content)
      end

      def serialize_and_save_to_repo__fold_into_existing?(assembly_dsl_path, serialized_content)
        begin
          @serialized_assembly_file ||= fold_into_existing_assembly_dsl(assembly_dsl_path, serialized_content)
          @service_module_branch.save_file_content_to_repo(assembly_dsl_path, @serialized_assembly_file)
         rescue => e
          #In case any error in routine to incrementally fold in to assembly we will just generate from new content (i.e., from fresh)
          Log.error_pp([e])
          serialize_and_save_to_repo__fresh?(assembly_dsl_path, serialized_content)
        end
      end

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
    end
  end
end
