module DTK
  class ServiceModule
    class AssemblyExport < Hash
      r8_nested_require('assembly_export','components_hash')

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
require 'debugger'
Debugger.wait_connection = true
Debugger.start_remote
debugger
        hash_assembly = ordered_hash_serialized_content[:assembly]
        if hash_nodes = hash_assembly && hash_assembly[:nodes]
          validate_components_order(path, hash_nodes)
        end

        # old_assembly_yaml = @service_module_branch.get_file_content(path, ordered_hash_serialized_content)
        @service_module_branch.serialize_and_save_to_repo?(path, ordered_hash_serialized_content)
        path
      end

      def validate_components_order(path, hash_nodes)
        raw_content    = @service_module_branch.get_raw_file_content(path)
        parsed_content = YAML.load(raw_content)
        assembly       = parsed_content['assembly']
        ordered_hash   = {}

        if nodes = assembly && assembly['nodes']
          cmp_hash = ComponentsHash.new(nodes)
          ordered_hash = cmp_hash.order_components_hash(hash_nodes)
        end

        ordered_hash
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
        # @factory.assembly_instance.get_field?(:description)
        @factory[:description]||@factory[:display_name]
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
