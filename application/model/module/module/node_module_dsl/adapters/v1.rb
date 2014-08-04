module DTK
  class NodeModuleDSL
    class V1 < self
      def self.parse_check(input_hash)
        # TODO: stub
      end
      def self.normalize(input_hash_x)
        pp [:hash_to_parse,input_hash_x]
        #TODO: below puts it in more convenient form that facilitates parsing
        input_hash = ObjectModelForm::InputHash.new(input_hash_x)
        #code that parses here
        input_hash #TODO: stub; no parsing
      end
    end
  end
end
