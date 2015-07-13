module DTK
  class ServiceModule
    class AssemblyExport < Hash
      r8_nested_require('assembly_export', 'components_hash')

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

      def save_to_model
        Model.input_hash_content_into_model(@container_idh,self,preserve_input_hash: true)
      end

      def serialize_and_save_to_repo?
        path = assembly_meta_filename_path()
        ordered_hash_serialized_content = serialize()

        hash_assembly = ordered_hash_serialized_content[:assembly]
        if hash_assembly && hash_assembly[:nodes]
          serialized_assembly_file = serialize_assembly_parts(path, ordered_hash_serialized_content)
          @service_module_branch.save_file_content_to_repo(path, serialized_assembly_file)
        else
          @service_module_branch.serialize_and_save_to_repo?(path, ordered_hash_serialized_content)
        end

        path
      end

      def serialize_assembly_parts(path, hash)
        raw_content = @service_module_branch.get_raw_file_content(path)
        line_array  = []

        raw_content.each_line do |line|
          line_array << line
        end

        assembly_hash = { assembly: hash.delete(:assembly) }
        workflow_hash = { workflow: hash.delete(:workflow) }

        serialized_assembly_file = Aux.serialize(hash, :yaml)

        components_hash       = ComponentsHash.new(line_array)
        assembly_hash         = components_hash.parse_and_order_components_hash(assembly_hash)
        assembly_string       = Aux.serialize(assembly_hash, :yaml).gsub("---\n", '')
        assembly_file_content = add_empty_lines_and_comments(assembly_string)

        serialized_assembly_file.concat(assembly_file_content)

        workflow_string = Aux.serialize(workflow_hash, :yaml).gsub("---\n", '')
        serialized_assembly_file.concat(workflow_string)

        serialized_assembly_file
      end

      def add_empty_lines_and_comments(assembly_string)
        assembly_file_content = ''

        assembly_string.each_line do |line|
          str_line = line.strip.gsub('- ', '')
          if str_line.eql?("''")
            assembly_file_content << "\n"
          elsif str_line.start_with?('!') && str_line.include?('#')
            assembly_file_content << line.gsub(/- ! '(#*\s*\w*)'/,  '\1')
          else
            assembly_file_content << line
          end
        end

        assembly_file_content
      end

      private

      include ServiceDSLCommonMixin

      def self.load_and_return_version_adapter_class(integer_version)
        return CachedAdapterClasses[integer_version] if CachedAdapterClasses[integer_version]
        adapter_name = "v#{integer_version}"
        opts = {
          class_name: { adapter_type: 'AssemblyExport' },
          subclass_adapter_name: true,
          base_class: ServiceModule
        }
        CachedAdapterClasses[integer_version] = DynamicLoader.load_and_return_adapter_class("assembly_export",adapter_name,opts)
      end
      CachedAdapterClasses = {}
      
      def assembly_meta_filename_path
        ServiceModule.assembly_meta_filename_path(assembly_hash()[:display_name],@service_module_branch)
      end

      def assembly_hash
        self[:component].values.first
      end

      def dsl_version?
        ServiceModule::DSLVersionInfo.integer_version_to_version(@integer_version)
      end
      
      def assembly_description?
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
