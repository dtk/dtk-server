module DTK
  class DocGenerator
    ###
    # DTK Model (.yaml) is not in mustache-friendly format, so we transform it in domain class bellow
    #
    module Domain
      class Module
        attr_accessor :name, :dsl_version, :type, :components
        
        def initialize(data)
          @name = data[:module]
          @dsl_version = data[:dsl_version]
          @type = data[:module_type]
          @components = []
          (data[:components] || {}).each do |name, comp_data|
            @components << Domain::Component.new(name, comp_data).instance_values
          end
        end
      end
      
      class Component
        attr_accessor :name, :attributes, :external_ref
        
        def initialize(name, data_hash)
          @attributes = []
          @name = name
          @external_ref = data_hash[:external_ref]
          (data_hash[:attributes] || {}).each do |attr_name, comp_data|
            @attributes << Domain::Attribute.new(attr_name, comp_data).instance_values
          end
        end
      end
      
      class Attribute
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

