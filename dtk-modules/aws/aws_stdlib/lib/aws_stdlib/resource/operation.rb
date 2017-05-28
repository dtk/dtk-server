module DTKModule
  class Aws::Stdlib::Resource
    # This is an abstract class and so is Aws::Stdlib::Resource
    # The classes InputSettings, OutputSettings need to be defined on the concrete resource or concrete operation
    #  The operaion is checked first
    class Operation
      require_relative('operation/input_settings')
      require_relative('operation/class_method')

      include InputSettings::Mixin
      extend InputSettings::ClassMixin

      def initialize(resource)
        @client = resource.client
        @params = check_and_return_input_settings(resource.attributes, resource_class)
      end
      
      attr_reader :client, :params

      def self.method_missing(method, object_called_from, *args, &block)
        self::ClassMethod.new(object_called_from, resource_class).send(method, *args, &block)
      end

      def self.aws_api_operation_class(operation_type)
        const_get camelize(operation_type)
      end

      private


      ### For output settings

      def output_settings(aws_result_object)
        self.class.output_settings(aws_result_object)
      end

      def self.output_settings(aws_result_object)
        output_settings_class(resource_class).create_from_aws_result_object(aws_result_object)
      end

      def self.output_settings_class(resource_class)
        @output_settings_class ||= (self.constants.include?(:OutputSettings) ? self::OutputSettings : resource_class::OutputSettings)
      end

      def resource_class
        self.class.resource_class
      end

      def self.resource_class
        fail "This method should be overwritten by concrete class"
      end

      ## Taken from Sequel
      def self.camelize(str_x, first_letter_in_uppercase = :upper)
        str = str_x.to_s
        s = str.gsub(/\/(.?)/) { |x| "::#{x[-1..-1].upcase unless x == '/'}" }.gsub(/(^|_)(.)/) { |x| x[-1..-1].upcase }
        s[0...1] = s[0...1].downcase unless first_letter_in_uppercase == :upper
        s
      end

    end
  end
end

