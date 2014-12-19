module DTK
  class ServiceModule
    class AssemblyExport < Hash
      attr_reader :factory
      def self.create(factory,container_idh,service_module_branch,integer_version=nil)
        integer_version ||= DSLVersionInfo.default_integer_version()
        klass = load_and_return_version_adapter_class(integer_version)
        klass.new(factory,container_idh,service_module_branch,integer_version)
      end

      def initialize(factory,container_idh,service_module_branch,integer_version)
        super()
        @container_idh = container_idh
        @service_module_branch = service_module_branch
        @integer_version = integer_version
        @factory = factory
      end
      private :initialize

      def save_to_model()
        Model.input_hash_content_into_model(@container_idh,self,:preserve_input_hash=>true)
      end

      def serialize_and_save_to_repo?()
        path = assembly_meta_filename_path()
        ordered_hash_serialized_content = serialize()
        @service_module_branch.serialize_and_save_to_repo?(path,ordered_hash_serialized_content)
        path
      end

     private
      include ServiceDSLCommonMixin

      def self.load_and_return_version_adapter_class(integer_version)
        return CachedAdapterClasses[integer_version] if CachedAdapterClasses[integer_version]
        adapter_name = "v#{integer_version.to_s}"
        opts = {
          :class_name => {:adapter_type => "AssemblyExport"},
          :subclass_adapter_name => true,
          :base_class => ServiceModule
        }
        CachedAdapterClasses[integer_version] = DynamicLoader.load_and_return_adapter_class("assembly_export",adapter_name,opts)
      end
      CachedAdapterClasses = Hash.new
      
      def assembly_meta_filename_path()
        ServiceModule.assembly_meta_filename_path(assembly_hash()[:display_name],@service_module_branch)
      end

      def assembly_hash()
        self[:component].values.first
      end

      def dsl_version?()
        ServiceModule::DSLVersionInfo.integer_version_to_version(@integer_version)
      end
      
      def assembly_description?()
        @factory.assembly_instance.get_field?(:description)
      end

      def component_output_form(component_hash)
        name = component_name_output_form(component_hash[:display_name])
        if attr_overrides = component_hash[:attribute_override]
          {name => attr_overrides_output_form(attr_overrides)}
        else
          name 
        end
      end
      def component_name_output_form(internal_format)
        internal_format.gsub(/__/,Seperators[:module_component])
      end

    end
  end
end
