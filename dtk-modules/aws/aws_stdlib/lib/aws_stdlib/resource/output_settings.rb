module DTKModule
  class Aws::Stdlib::Resource
    # This is asbtract class
    class OutputSettings < DTK::Settings
      # Concrete class neees to define ATTRIBUTE_MAPPING, which could have one of three forms
      # ATTRIBUTE_MAPPING = 
      # [
      #     :instance_id, # dtk attribute name same as aws attribute name 
      #   { :op_state => instance_state }, dtk attribute on left side gets value from scalar on right side
      #   { :block_device_mappings => { :fn => :map_block_device_mappings } # dtk attribute on left side gets from function call that gets the whole aws object
      # ]

      def self.create_from_aws_result_object(aws_result_object)
        dynamic_keys.inject(new) { |h, key| h.merge(key => transform_value(key, aws_result_object)) }
      end

      def self.empty
        new
      end

      private

      def self.transform_value(key, aws_result_object)
        if rhs = method?(key)
          transform_value_with_rhs(key, rhs, aws_result_object)
        else
          aws_result_object.send(key)
        end
      end

      FUNCTION_KEY = :fn
      def self.transform_value_with_rhs(key, rhs, aws_result_object)
        ret = 
          if rhs.kind_of?(::Hash) 
            if method = rhs[FUNCTION_KEY]
              send(method, aws_result_object)
            end
          elsif rhs.kind_of?(::Symbol)
            aws_result_object.send(rhs)
          end
        ret || fail("Unexpected form for right hand side for ATTRIBUTE_MAPPING[#{key}]: #{rhs.inspect}")
      end
        
      def self.method?(key)
        ndx_mapping[key]
      end

      def self.ndx_mapping
        @ndx_mapping ||= self::ATTRIBUTE_MAPPING.inject({}) { |h, el| el.kind_of?(::Symbol) ? h.merge(el => nil) : h.merge(el) }
      end
      
      def self.dynamic_keys
        @dynamic_keys ||= ndx_mapping.keys
      end

    end
  end
end
