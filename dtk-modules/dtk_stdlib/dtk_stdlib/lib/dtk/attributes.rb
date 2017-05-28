module DTKModule
  module DTK
    class Attributes
      module Mixin
        def wrap(av_hash, &body)
          begin 
            response = body.call(Attributes.new(av_hash))
            response.respond_to?(:hash_form) ? response.hash_form : response
          rescue Error::Usage => usage_error
            usage_error.hash_form
          rescue  => e
            Error::Internal.new(e).hash_form
          end
        end
      end
      
      def initialize(av_hash)
        @av_hash = av_hash
      end

      def value?(*attribute_names)
        ret = attribute_names.map { |attribute_name| av_hash[attribute_name] if has_value?(attribute_name) }
        ret.size == 1 ? ret.first : ret
      end
      #synonym
      def values?(*attribute_names)
        value?(*attribute_names)
      end
      
      def value(*attribute_names)
        raise_if_missing_attributes(*attribute_names)
        values?(*attribute_names)
      end
      #synonym
      def values(*attribute_names)
        value(*attribute_names)
      end

      def set_value!(attribute_name, value)
        av_hash[attribute_name] = value
      end
      
      def required_hash_subset(*attribute_names)
        raise_if_missing_attributes(*attribute_names)
        attribute_names.inject({}) { |h, attribute_name| h.merge(attribute_name => av_hash[attribute_name]) }
      end

      DEBUG_ATTRIBUTE = :dtk_debug
      def debug_break_point?
        if "#{value?(DEBUG_ATTRIBUTE) || ''}" == 'true'
          require 'byebug'; byebug
        end
      end

      private
      
      attr_reader :av_hash

      def has_value?(attribute_name)
        !av_hash[attribute_name].nil?
      end
      
      def raise_if_missing_attributes(*attribute_names)
        missing_attributes = attribute_names.reject { |attribute_name| has_value?(attribute_name) }
        unless missing_attributes.empty?
          error_msg = (attribute_names.size == 1 ? "Missing attribute '#{attribute_names.first}'" : "Missing attributes (#{attribute_names.join(', ')})")
          fail Error::Usage, error_msg
        end
      end

    end
  end
end
