module DTK
  module Utils
    module MethodLogger
      def self.extended(base)
        clazz_methods = base.methods(false)

        base.class_eval do
          clazz_methods.each do |method_name|
            original_method = method(method_name).unbind
            define_singleton_method(method_name) do |*args, &block|
              puts "$$---> #{base}##{method_name}(#{args.inspect})"
              return_value = original_method.bind(self).call(*args, &block)
              puts "<---$$ #{base}##{method_name} #=> #{return_value.inspect}"
              return_value
            end
          end
        end
      end

      def self.included(base)
        methods = base.instance_methods(false) + base.private_instance_methods(false)

        base.class_eval do
          methods.each do |method_name|
            original_method = instance_method(method_name)
            define_method(method_name) do |*args, &block|
              puts "$$---> #{base}.instance##{method_name}(#{args.inspect})"
              return_value = original_method.bind(self).call(*args, &block)
              puts "<---$$ #{base}.instance##{method_name} #=> #{return_value.inspect}"
              return_value
            end
          end
        end
      end
    end
  end
end