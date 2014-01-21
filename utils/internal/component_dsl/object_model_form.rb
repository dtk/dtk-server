module DTK; class ComponentDSL
  class ObjectModelForm
    r8_nested_require('object_model_form','parsing_error')

    def self.convert(input_hash)
      new.convert(input_hash)
    end
   private
    def component_print_form(cmp_internal_form)
      ::DTK::Component.display_name_print_form(cmp_internal_form)
    end

    class InputHash < Hash
      def initialize(hash={})
        unless hash.empty?()
          replace(convert(hash))
        end
      end
      
      def req(key)
        key = key.to_s
        unless has_key?(key)
          raise ParsingError::MissingKey.new(key)
        end
        self[key]
      end
     private
      def convert(item)
        if item.kind_of?(Hash)
          item.inject(InputHash.new){|h,(k,v)|h.merge(k => convert(v))}
        elsif item.kind_of?(Array)
          item.map{|el|convert(el)}
        else
          item
        end
      end
    end

    class OutputHash < Hash
      def initialize(hash={})
        unless hash.empty?()
          replace(hash)
        end
      end
      def set_if_not_nil(key,val)
        self[key] = val unless val.nil?
      end
    end

  end
end; end

