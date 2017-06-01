module DTKModule
  class Aws::Stdlib::Resource::Operation
    module InputSettings
      module Mixin
        def check_and_return_input_settings(attributes, resource_class)
          input_settings_class = self.class.input_settings_class
          operations_class     = self.class

          missing_attributes = input_settings_class.required.select { |attr| attributes.value?(attr).nil? }
          InputSettings.raise_missing_attributes(missing_attributes, resource_class, operations_class) unless missing_attributes.empty?
          input_settings_class.settings_from_attributes(attributes)
        end
      end

      module ClassMixin
        def input_settings_class
          @input_settings_class ||= (self.constants.include?(:InputSettings) ? self::InputSettings : resource_class::InputSettings)
        end
      end
      
      def self.raise_missing_attributes(missing_attributes, resource_class, operations_class)
        resource_name  = snake_form(demodularize(resource_class).downcase)
        operation_name = snake_form(demodularize(operations_class))
        error_msg = 
          if missing_attributes.size > 1
            "The following attributes are needed for operation '#{operation_name} on resource '#{resource_name}', but are missing: #{missing_attributes.join(', ')}"
          else
            "The attribute '#{missing_attributes.first}' is missing, but needed for operation '#{operation_name}' on resource '#{resource_name}'"
          end
        fail DTK::Error::Usage, error_msg
      end
      
      private

      # Strips off the nesting modules
      def self.demodularize(klass)
        klass.to_s.split('::').last
      end

      # camel case to snake form
      def self.snake_form(str)
        str.gsub(/::/, '/').gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z\d])([A-Z])/, '\1_\2').tr('-', '_').downcase
      end
      
    end
  end
end

