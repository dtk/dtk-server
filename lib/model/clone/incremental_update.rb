module DTK; class Clone
  # These mdouels explicitly have class to the sub object type in contrast to 
  # initial clone, which does not              
  module IncrementalUpdate
    r8_nested_require('incremental_update','component')
    class InstanceTemplateLinks < Hash
      def add(instance,template)
        self[key(instance)] = {:instance => instance, :template => template}
      end
      def template(instance)
        (self[key(instance)]||{})[:template] || 
          raise(Error.new("Cannot find matching template for instance (#{instance.inspect})"))
      end
      private
      def key(instance)
        instance.id()
      end
    end
  end
end; end
