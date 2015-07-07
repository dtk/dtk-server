module DTK; class NodeBindings
  class NodeTarget
    class Image < self
      attr_reader :image
      def initialize(hash)
        super(Type)
        @image = hash[:image]
        @size = hash[:size]
      end

      # returns a TargetSpecificObject
      def find_target_specific_info(target)
        ret = TargetSpecificInfo.new(self)
        if @image
          unless image_id = NodeImage.find_iaas_match(target,@image)
            raise ErrorUsage.new("The image (#{@image}) in the node binding does not exist in the target (#{target.get_field?(:display_name)})")
          end
          ret.image_id = image_id
        end
        if @size
          unless iaas_size = NodeImageAttribute::Size.find_iaas_match(target,@size)
            raise ErrorUsage.new("The size (#{@size}) in the node binding is not valid in the target (#{target.get_field?(:display_name)})")
          end
          ret.size = iaas_size
        end
        ret
      end

      def hash_form
        {type: type().to_s, image: @image, size: @size} 
      end

      Type = :image
      Fields = {
        image: {
          key: 'image',
          required: true
        },
        size: {
          key: 'size'
        }
      }
      InputFormToInternal = Fields.inject({}){|h,(k,v)|h.merge(v[:key] => k)}
      Allkeys = Fields.values.map{|f|f[:key]}
      RequiredKeys =  Fields.values.select{|f|f[:required]}.map{|f|f[:key]}

      def self.parse_and_reify(parse_input,_opts={})
        ret = nil
        if parse_input.type?(ContentField)
          input = parse_input.input
          if input[:type].to_sym == Type
            ret = new(input)
          end
        elsif parse_input.type?(Hash)
          input = parse_input.input
          if Aux.has_only_these_keys?(input,Allkeys) && ! RequiredKeys.find{|k| !input.key?(k)}
            internal_form_hash = input.inject({}){|h,(k,v)|h.merge(InputFormToInternal[k] => v)} 
            ret = new(internal_form_hash)
          end
        end
        ret
      end

      def match_or_create_node?(_target)
        :create
      end
    end
  end
end; end
