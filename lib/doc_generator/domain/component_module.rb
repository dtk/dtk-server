module DTK; class DocGenerator
  class Domain
    class ComponentModule < self
      def self.normalize_top(parsed_dsl__component_module)
        raw_input        = active_support_with_indifferent_access(parsed_dsl__component_module.raw_hash)
        normalized_input = active_support_with_indifferent_access(parsed_dsl__component_module.version_normalized_hash)
        { :module => normalize(raw_input[:module], raw_input, normalized_input) }
      end
      
      attr_accessor :name, :dsl_version, :components
      
      def initialize(name, raw_input, normalized_input = nil)
        @name = raw_input[:module]
        @dsl_version = raw_input[:dsl_version]
        @components = []
        (raw_input[:components] || {}).each do |cmp_name, raw_component|
          @components << Component.normalize(cmp_name, raw_component)
        end
      end
    end
      
    class Component < self
      attr_accessor :name, :attributes, :external_ref
      
      def initialize(name, raw_input, normalized_input = nil)
        @attributes = []
        @name = name
        @external_ref = raw_input[:external_ref]
        (raw_input[:attributes] || {}).each do |attr_name, raw_attr|
          @attributes << Attribute.normalize(attr_name, raw_attr)
        end
      end
    end
    
    class Attribute < self
      attr_accessor :name, :type, :required
      
      def initialize(name, raw_input, normalized_input = nil)
        @name = name
        @type = raw_input[:type]
        @required = raw_input[:required]
      end

    end
  end
end; end



