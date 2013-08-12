module DTK
  class ServiceModule
    class AssemblyExport < Hash
      def self.create(container_idh,service_module_branch,integer_version=nil)
        klass = load_and_return_version_adapter_class(integer_version)
        klass.new(container_idh,service_module_branch)
      end

      def save_to_model()
        Model.input_hash_content_into_model(@container_idh,self,:preserve_input_hash=>true)
      end

      def serialize_and_save_to_repo()
        path = assembly_meta_filename_path()
        ordered_hash_serialized_content = serialize()
        @service_module_branch.serialize_and_save_to_repo(path,ordered_hash_serialized_content)
        path
      end

     private
      include AssemblyImportExportCommon

      def self.load_and_return_version_adapter_class(integer_version=nil)
        integer_version ||= R8::Config[:dsl][:service][:integer_version][:default]
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
      
      def initialize(container_idh,service_module_branch)
        super()
        @container_idh = container_idh
        @service_module_branch = service_module_branch
      end

      def assembly_meta_filename_path()
        ServiceModule.assembly_meta_filename_path(assembly_hash()[:display_name])
      end

      def assembly_hash()
        self[:component].values.first
      end

      def component_output_form(component_hash)
        name = component_name_output_form(component_hash[:component_type])
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
