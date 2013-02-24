module DTK
  class Assembly::Template
    class Output < Hash
      def self.create(container_idh,service_module_branch,integer_version=nil)
        klass = load_and_return_version_adapter_class(integer_version)
        klass.new(container_idh,service_module_branch)
      end

      def save_to_model()
        Model.input_hash_content_into_model(@container_idh,self,:preserve_input_hash=>true)
      end

      def serialize_and_save_to_repo()
        hash_to_serialize = serialize()
        ordered_hash_content = SimpleOrderedHash.new([:node_bindings,:assemblies].map{|k|{k => hash_to_serialize[k]}})
        path = assembly_meta_filename_path()
        @service_module_branch.serialize_and_save_to_repo(path,ordered_hash_content)
        path
      end

     private
      include AssemblyImportExportCommon

      def self.load_and_return_version_adapter_class(integer_version=nil)
        integer_version ||= R8::Config[:dsl][:service][:integer_version][:default]
        return CachedAdapterClasses[integer_version] if CachedAdapterClasses[integer_version]
        adapter_name = "v#{integer_version.to_s}"
        opts = {
          :class_name => {:adapter_type => "Output"},
          :subclass_adapter_name => true,
          :base_class => Assembly::Template
        }
        CachedAdapterClasses[integer_version] = DynamicLoader.load_and_return_adapter_class("output",adapter_name,opts)
      end
      CachedAdapterClasses = Hash.new
      
      def initialize(container_idh,service_module_branch)
        super()
        @container_idh = container_idh
        @service_module_branch = service_module_branch
      end

    end
  end
end
