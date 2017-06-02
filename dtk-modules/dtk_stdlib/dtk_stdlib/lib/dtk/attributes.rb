module DTKModule
  module DTK
    class Attributes
      require_relative('attributes/attribute_type')
      module Mixin
        # opts can have keys:
        #   :attributes_class
        def wrap(av_hash, opts = {},& body)
          begin 
            attributes_class = opts[:attributes_class] || Attributes
            response = 
              case body.arity
              when 1
                body.call(attributes_class.new(av_hash))
              when 3
                split_av_hash = AttributeType.split(av_hash)
                args = [split_av_hash[:component], split_av_hash[:assembly_level], split_av_hash[:system]].map { |av_hash|  attributes_class.new(av_hash)}
                body.call(*args)
              else
                fail "Arity of body must be 1 or 3"
              end
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
