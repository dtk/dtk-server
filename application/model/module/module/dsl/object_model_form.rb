module DTK; class ModuleDSL
  class ObjectModelForm
    extend Aux::CommonClassMixin

    def self.convert(input_hash)
      new.convert(input_hash)
    end

    private

    def convert_to_hash_form(obj, &block)
      self.class.convert_to_hash_form(obj, &block)
    end
    def self.convert_to_hash_form(obj, &block)
      if obj.is_a?(Hash)
        obj.each_pair { |k, v| block.call(k, v) }
      else
        obj = [obj] unless obj.is_a?(Array)
        obj.each do |el|
          if el.is_a?(Hash)
            block.call(el.keys.first, el.values.first)
          else #el.kind_of?(String)
            block.call(el, {})
          end
        end
      end
    end

    ModCmpDelim = '__'
    CmpPPDelim = '::'
    def convert_to_internal_cmp_form(cmp)
      self.class.convert_to_internal_cmp_form(cmp)
    end
    def self.convert_to_internal_cmp_form(cmp)
      cmp.gsub(Regexp.new(CmpPPDelim), ModCmpDelim)
    end
    # TODO: above should call DTK::Component methods and not need the Constants here
    def component_print_form(cmp_internal_form)
      self.class.component_print_form(cmp_internal_form)
    end
    def self.component_print_form(cmp_internal_form)
      ::DTK::Component.display_name_print_form(cmp_internal_form)
    end

    def matching_key?(key_or_keys, input_hash)
      if key_or_keys.is_a?(Array)
        keys = key_or_keys
        if match = keys.find { |k| input_hash.key?(k) }
          input_hash[match]
        end
      else
        key = key_or_keys
        input_hash[key]
      end
    end

    class InputHash < Hash
      def initialize(hash = {})
        unless hash.empty?()
          replace(convert(hash))
        end
      end

      def req(key)
        key = key.to_s
        unless key?(key)
          fail ParsingError::MissingKey.new(key)
        end
        self[key]
      end

      private

      def convert(item)
        if item.is_a?(Hash)
          item.inject(InputHash.new) { |h, (k, v)| h.merge(k => convert(v)) }
        elsif item.is_a?(Array)
          item.map { |el| convert(el) }
        else
          item
        end
      end
    end

    class OutputHash < Hash
      def initialize(hash = {})
        unless hash.empty?()
          replace(hash)
        end
      end

      def set_if_not_nil(key, val)
        self[key] = val unless val.nil?
      end
    end
  end
end; end
