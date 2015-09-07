module DTK
  class DocGenerator
    class Domain
      r8_nested_require('domain', 'active_support_instance_variables')
      extend ActiveSupportInstanceVariablesMixin

      def self.normalize(dsl_object)
        raw_input        = active_support_with_indifferent_access(dsl_object.raw_hash)
        normalized_input = active_support_with_indifferent_access(dsl_object.version_normalized_hash)
        Module.normalize(raw_input[:module], raw_input, normalized_input)
      end

      class BaseObject
        extend ActiveSupportInstanceVariablesMixin

        def self.normalize(name, raw_input, normalized_input = nil)
          active_support_instance_values(new(name, raw_input, normalized_input))
        end
      end

      class Module < BaseObject
        attr_accessor :name, :dsl_version, :components
        
        def initialize(name, raw_input, normalized_input = nil)
          @name = raw_input[:module]
          @dsl_version = raw_input[:dsl_version]
          @components = []
          (raw_input[:components] || {}).each do |cmp_name, raw_component|
            @components << Domain::Component.normalize(cmp_name, raw_component)
          end
        end
      end
      
      class Component < BaseObject
        attr_accessor :name, :attributes, :external_ref
        
        def initialize(name, raw_input, normalized_input = nil)
          @attributes = []
          @name = name
          @external_ref = raw_input[:external_ref]
          (raw_input[:attributes] || {}).each do |attr_name, raw_attr|
            @attributes << Domain::Attribute.new(attr_name, raw_attr)
          end
        end
      end
      
      class Attribute < BaseObject
        attr_accessor :name, :type, :required
        
        def initialize(name, raw_input, normalized_input = nil)
          @name = name
          @type = raw_input[:type]
          @required = raw_input[:required]
        end
      end
    end

  end
end


