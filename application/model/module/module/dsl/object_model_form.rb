module DTK; class ModuleDSL
  class ObjectModelForm
    extend Aux::CommonClassMixin

    def self.convert(input_hash)
      new.convert(input_hash)
    end

    def convert_children(input_hash)
      illegal_keys = input_hash.keys - all_keys() 
      unless illegal_keys.empty?
        raise ParsingError::IllegalKeys.new(illegal_keys)
      end
      input_hash.req(:foo)
    end

   private
    def all_keys()
      self.class.all_keys()
    end
    def self.all_keys()
      @all_keys ||= fields_cached().map{|(k,v)|v[:key]}
    end
    def self.fields_cached()
      return @fields if @fields 
      @fields = fields()
      @fields.each_key{|k|@fields[k][:key]||=k.to_s}
      @fields
    end
    def self.fields()
      raise Error.new("field should be over-written")
    end

    def convert_to_hash_form(hash_or_array,&block)
      self.class.convert_to_hash_form(hash_or_array,&block)
    end
    def self.convert_to_hash_form(hash_or_array,&block)
      if hash_or_array.kind_of?(Hash)
        hash_or_array.each_pair{|k,v|block.call(k,v)}
      else #hash_or_array.kind_of?(Array)
        hash_or_array.each do |el|
          if el.kind_of?(Hash)
            block.call(el.keys.first,el.values.first)
          else #el.kind_of?(String)
            block.call(el,Hash.new)
          end
        end
      end
    end

    ModCmpDelim = "__"
    CmpPPDelim = '::'
    def convert_to_internal_cmp_form(cmp)
      self.class.convert_to_internal_cmp_form(cmp)
    end
    def self.convert_to_internal_cmp_form(cmp)
      cmp.gsub(Regexp.new(CmpPPDelim),ModCmpDelim)
    end
    # TODO: above should call DTK::Component methods and not need the Constants here
    def component_print_form(cmp_internal_form)
      self.class.component_print_form(cmp_internal_form)
    end
    def self.component_print_form(cmp_internal_form)
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

