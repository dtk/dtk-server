module DTK
  class DocGenerator
    ###
    # DTK Model (.yaml) is not in mustache-friendly format, so we transform it in domain class bellow
    #
    class Domain
      r8_nested_require('domain', 'active_support_instance_variables')
      extend ActiveSupportInstanceVariablesMixin
      include ActiveSupportInstanceVariablesMixin

      def self.normalize(content)
        active_support_instance_values(Module.new(active_support_with_indifferent_access(content)))
      end
      
      class Module < self
        attr_accessor :name, :dsl_version, :type, :components
        
        def initialize(data)
          @name = data[:module]
          @dsl_version = data[:dsl_version]
          @type = data[:module_type]
          @components = []
          (data[:components] || {}).each do |name, comp_data|
            @components << active_support_instance_values(Domain::Component.new(name, comp_data))
          end
        end
      end
      
      class Component < self
        attr_accessor :name, :attributes, :external_ref
        
        def initialize(name, data_hash)
          @attributes = []
          @name = name
          @external_ref = data_hash[:external_ref]
          (data_hash[:attributes] || {}).each do |attr_name, comp_data|
            @attributes << active_support_instance_values(Domain::Attribute.new(attr_name, comp_data))
          end
        end
      end
      
      class Attribute < self
        attr_accessor :name, :type, :required
        
        def initialize(name, data_hash)
          @name = name
          @type = data_hash[:type]
          @required = data_hash[:required]
        end
      end
    end

  end
end


