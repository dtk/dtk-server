module DTK
  class Error
    class ErrorNotFound < self
      attr_reader :obj_type,:obj_value
      def initialize(obj_type=nil,obj_value=nil)
        @obj_type = obj_type
        @obj_value = obj_value
      end

      def to_s
        if obj_type.nil?
          "NotFound error:" 
        elsif obj_value.nil?
          "NotFound error: type = #{@obj_type}"
        else
          "NotFound error: #{@obj_type} = #{@obj_value}"
        end
      end

      def to_hash
        if obj_type.nil?
          {error: :NotFound}
        elsif obj_value.nil?
          {error: {NotFound: {type: @obj_type}}}
        else
          {error: {NotFound: {type: @obj_type, value: @obj_value}}}
        end
      end
    end
  end
end
