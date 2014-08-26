module DTK; class NodeBindings
  class NodeTarget
    class Image < self
<<<<<<< HEAD
      attr_reader :image
=======
>>>>>>> namespace_support_merged
      def initialize(hash)
        super(Type)
        @image = hash[:image]
        @size = hash[:size]
      end
<<<<<<< HEAD

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

=======
      Type = :image
>>>>>>> namespace_support_merged
      def hash_form()
        {:type => type().to_s, :image => @image, :size => @size} 
      end

<<<<<<< HEAD
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

=======
>>>>>>> namespace_support_merged
      def self.parse_and_reify(parse_input,opts={})
        ret = nil
        if parse_input.type?(ContentField)
          input = parse_input.input
          if input[:type].to_sym == Type
            ret = new(input)
          end
        elsif parse_input.type?(Hash)
          input = parse_input.input
<<<<<<< HEAD
          if Aux.has_only_these_keys?(input,Allkeys) and ! RequiredKeys.find{|k| !input.has_key?(k)}
            internal_form_hash = input.inject(Hash.new){|h,(k,v)|h.merge(InputFormToInternal[k] => v)} 
            ret = new(internal_form_hash)
=======
          if Aux.has_only_these_keys?(input,['image','size']) and input['image']
            ret = new(input)
>>>>>>> namespace_support_merged
          end
        end
        ret
      end
<<<<<<< HEAD
      
=======

>>>>>>> namespace_support_merged
      def match_or_create_node?(target)
        :create
      end
    end
  end
end; end
