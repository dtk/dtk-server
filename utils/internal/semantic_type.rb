# TODO: move this to under attribute or attribute_link
module DTK
  module CommonSemanticTypeMixin
    def is_array?
      # TODO: may have :array+ and :array* to distinguish whether array can be empty
      keys.first == :array
    end

    def is_hash?
      not (is_array?() || is_atomic?())
    end
  end
  class SemanticType < HashObject
    include CommonSemanticTypeMixin
    def self.create_from_attribute(attr)
      semantic_type = attr[:semantic_type]
      return SemanticTypeSimple.new(semantic_type) unless semantic_type.is_a?(Hash)

      self.new(convert_hash(semantic_type))
    end

    def is_atomic?
      nil
    end

    private

    def self.convert_hash(item)
      return item unless item.is_a?(Hash)
      item.inject({}) do |h,kv|
        new_key = kv[0].to_s =~ /^:(.+$)/ ? $1.to_sym : kv[0].to_s
        h.merge(new_key =>  convert_hash(kv[1]))
      end
    end
  end
  class SemanticTypeSimple < SemanticType
    def initialize(val)
      @value = val
      super()
    end

    def is_array?
      nil
    end
  end

  # TODO: for input ports may just have constraints, not syntax
  module AttributeSemantic
    # TODO: rather than external may have :internal_only
    Info =
      # L4 Saps adn sockets
      {
      "sap_config__l4" => {
        syntax: {
          "port" =>  {required: true, type: :integer},
          "protocol" => {required: true, type: :string},
          "binding_addr_constraints" => {type: :json}
        }
      },
      "sap__l4" => {
        external: true,
        port_type: "output",
        syntax: {
          "port" => {required: true, type: :integer},
          "protocol" => {required: true, type: :string},
          "host_address" => {required: true, dynamic: true, type: :string}
        }
      },
      # rather than having or having two sap refs and user can remove or add to component
      #       "sap_ref__l4" => {
      #         :external => true,
      #         :port_type => "input",
      #         :syntax => {
      #           :or =>
      #           [{
      #              "port" => {:required => true, :type => :integer},
      #              "protocol" => {:required => true, :type => :string},
      #              "host_address" => {:required => true, :type => :string}
      #            },
      #            {"socket_file" => {:required => true, :type => :string}}
      #           ]
      #         }
      #       },
      "sap_ref__l4" => {
        external: true,
        port_type: "input",
        syntax: {
           "port" => {required: true, type: :integer},
           "protocol" => {required: true, type: :string},
           "host_address" => {required: true, type: :string}
        }
      },

      "sap__socket" => {
        syntax: {
          "socket_file" => {required: true, type: :string}
        }
      },

      "db_user_access" => {
        external: true,
        # TODO: need to rexamine use of :port_type => "input" in light of having attributes that can be read only vs read/write depending
        # if they have alink; currently if marked as input then they are treated as readonly
        #        :port_type => "input",
        syntax: {
          "username" => {required: true, type: :string},
          "password" => {required: false, type: :string},
          "inet_access" => {required: true, type: :boolean},
          "client_host_addr" => {required: true, type: :string}
        }
      },

      # TODO: deprecate db ones in favor of above
      # DB params
      "db_config" => {
        external: true,
        port_type: "output",
        syntax: {
          "database" => {required: true, type: :string},
          "username" => {required: true, type: :string},
          "password" => {required: true, type: :string}
        }
      },
      "db_params" => {
        external: true,
        port_type: "input",
        syntax: {
          "database" => {required: true, type: :string},
          "username" => {required: true, type: :string},
          "password" => {required: true, type: :string}
        }
      },
      "db_ref" => {
        external: true,
        port_type: "input"
      },

      "service_check_input" => {
        port_type: "input"
      },

      # TODO: may deprecate below
      "sap_config__db" => {
      },
      "sap__db" => {
        external: true,
        port_type: "output"
      },
      "sap_ref__db" => {
        external: true,
        port_type: "input"
      },
    }
  end

  class SemanticTypeSchema < HashObject::AutoViv
    include CommonSemanticTypeMixin
    def self.create_from_attribute(attr)
      semantic_type = attr[:semantic_type]
      return nil unless semantic_type
      key = semantic_type_key(semantic_type)
      return TranslationToSchema[key] if TranslationToSchema[key]
      return create_from_semantic_type(semantic_type) if semantic_type.is_a?(Hash)
    end

    def self.create_from_semantic_type(semantic_type)
      return nil unless semantic_type
      key = semantic_type_key(semantic_type)
      return TranslationToSchema[key] if TranslationToSchema[key]

      ret = create()
      if semantic_type.is_a?(Hash)
        val = semantic_type.values.first
        return create_json_type() if val.is_a?(Hash) && val.keys.first == :application
        ret_schema_from_semantic_type_aux!(ret,key,val)
      end
      return nil if ret.empty?
      ret.freeze
    end

    def is_atomic?
      key?(:type)
    end

    # returns [array_body_pattern, whether_can_be_empty]
    def parse_array
      # TODO: may have :array+ and :array* to distingusih whether array can be empty
      [values.first,false]
    end

    def self.ret_scalar_defined_datatypes
      TranslationToSchema.keys
    end

    private

    def self.semantic_type_key(semantic_type)
      ret = (semantic_type.is_a?(Hash) ? semantic_type.keys.first : semantic_type).to_s
      ret == ":array" ? :array : ret
    end

    def self.ret_schema_from_semantic_type_aux!(ret,index,semantic_type)
      key = semantic_type_key(semantic_type)
      if TranslationToSchema[key]
        ret[index] = TranslationToSchema[key]
      elsif semantic_type.is_a?(Hash)
        ret_schema_from_semantic_type_aux!(ret[index],key,semantic_type.values.first)
      else
        ret[index] = create_json_type()
      end
    end

    def self.create_json_type
      SemanticTypeSchema.new(type: :json)
    end

    TranslationToSchema = self.new(AttributeSemantic::Info.inject({}){|h,kv|h.merge(kv[0] => kv[1][:syntax])},true)
  end
end
