module XYZ
  module CommonSemanticTypeMixin
    def is_array?()
      #TODO: may have :array+ and :array* to distinguish whether array can be empty
      keys.first == :array
    end
  end
  class SemanticType < HashObject
    def self.create_from_attribute(attr)
      semantic_type = attr[:semantic_type]
      return SemanticTypeSimple.new(semantic_type) unless semantic_type.kind_of?(Hash)
      self.new(semantic_type)
    end
  end
  class SemanticTypeSimple < SemanticType
    def initialize(val)
      @value = val
      super()
    end
    def is_array?()
      nil
    end
  end

  class SemanticTypeSchema < HashObject
    include CommonSemanticTypeMixin
    def self.create_from_attribute(attr)
      semantic_type = attr[:semantic_type]
      return nil unless semantic_type
      key = semantic_type_key(semantic_type)
      return TranslationToSchema[key] if TranslationToSchema[key]
      return create_from_semantic_type(semantic_type) if semantic_type.kind_of?(Hash)
    end
    
    def self.create_from_semantic_type(semantic_type)
      return nil unless semantic_type
      key = semantic_type_key(semantic_type)
      return TranslationToSchema[key] if TranslationToSchema[key]

      ret = create_with_auto_vivification()
      if  semantic_type.kind_of?(Hash)
        ret_schema_from_semantic_type_aux!(ret,key,semantic_type.values.first)
      end
      if ret.empty?
        Log.error("found semantic type #{semantic_type.inspect} that does not have a nested type definition")
        return nil
      end
      ret.freeze
    end

    def is_atomic?()
      has_key?(:type)
    end

    #returns [array_body_pattern, whether_can_be_empty]
    def parse_array()
      #TODO: may have :array+ and :array* to distingusih whether array can be empty
      [values.first,false]
    end

    private

    def self.semantic_type_key(semantic_type)
      ret = (semantic_type.kind_of?(Hash) ? semantic_type.keys.first : semantic_type).to_s
      ret == ":array" ? :array : ret
    end

    def self.ret_schema_from_semantic_type_aux!(ret,index,semantic_type)
      key = semantic_type_key(semantic_type)
      if TranslationToSchema[key]
        ret[index] = TranslationToSchema[key]
      elsif semantic_type.kind_of?(Hash)
        ret_schema_from_semantic_type_aux!(ret[index],key,semantic_type.values.first)        
      else
        ret[index] = SemanticType.new({:type => "json"})
      end
    end
    TranslationToSchema = self.new( 
    {
      "sap_config[ipv4]" => {
        "port" =>  {:required => true, :type => :integer},
        "protocol" => {:required => true, :type => :string},
        "binding_addr_constraints" => {:type => :json}
      },
      "sap[ipv4]" => {
        "port" => {:required => true, :type => :integer},
        "protocol" => {:required => true, :type => :string},
        "host_address" => {:required => true, :type => :string}
      },
      "sap_ref" => {
        :or => 
        [{
           "port" => {:required => true, :type => :integer},
           "protocol" => {:required => true, :type => :string},
           "host_address" => {:required => true, :type => :string}
         },
         {"socket_file" => {:required => true, :type => :string}}
        ]
      },
      "sap[socket]" => {
        "socket_file" => {:required => true, :type => :string}
      },
      
      "db_info" => {
        "username" => {:required => true, :type => :string},
        "database" => {:required => true, :type => :string},
        "password" => {:required => true, :type => :string}
      }
    },true)
  end

  module AttributeSemantic
    #TODO: rather than external may have :internal_only
    Info =
      {
      "sap_config[ipv4]" => {
      },
      "sap[ipv4]" => {
        :external => true,
        :port_type => "output"
      },
      "sap_ref" => {
        :external => true,
        :port_type => "input"
      },
      "sap[socket]" => {
      },
      "db_info" => {
#        :external => true,
      }
    }
  end
end
