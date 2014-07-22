module DTK; class NodeBindings
  class NodeTarget
    class Image < self
      def initialize(hash)
        super(Type)
        @image = hash[:image]
        @size = hash[:size]
      end
      Type = :image
      def hash_form()
        {:type => type().to_s, :image => @image, :size => @size} 
      end

      def self.parse_and_reify(parse_input,opts={})
        ret = nil
        if parse_input.type?(ContentField)
          input = parse_input.input
          if input[:type].to_sym == Type
            ret = new(input)
          end
        elsif parse_input.type?(Hash)
          input = parse_input.input
          if Aux.has_only_these_keys?(input,['image','size']) and input['image']
            ret = new(input)
          end
        end
        ret
      end

      def match_or_create_node?(target)
        :create
      end
    end
  end
end; end
