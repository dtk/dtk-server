module DTK; class NodeBindings
  class NodeTarget
    class Image < self
      def initialize(hash)
        super(Type)
        @image = hash[:image]
        @size = hash[:size]
      end
      
      def hash_form()
        {:type => type().to_s, :image => @image, :size => @size} 
      end

      Type = :image
      Fields = {
        :image => {
          :key => 'image',
          :required => true
        },
        :size => {
          :key => 'size'
        }
      }
      InputFormToInternal = Fields.inject(Hash.new){|h,(k,v)|h.merge(v[:key] => k)}
      Allkeys = Fields.values.map{|f|f[:key]}
      RequiredKeys =  Fields.values.select{|f|f[:required]}.map{|f|f[:key]}

      def self.parse_and_reify(parse_input,opts={})
        ret = nil
        if parse_input.type?(ContentField)
          input = parse_input.input
          if input[:type].to_sym == Type
            ret = new(input)
          end
        elsif parse_input.type?(Hash)
          input = parse_input.input
          if Aux.has_only_these_keys?(input,Allkeys) and ! RequiredKeys.find{|k| !input.has_key?(k)}
            internal_form_hash = input.inject(Hash.new){|h,(k,v)|h.merge(InputFormToInternal[k] => v)} 
            ret = new(internal_form_hash)
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
