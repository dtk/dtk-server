module DTK; class Clone
  # These mdouels explicitly have class to the sub object type in contrast to 
  # initial clone, which does not              
  module IncrementalUpdate
    r8_nested_require('incremental_update','component')
    class InstanceTemplateLinks < Array
      def initialize()
        super()
      end
      def add(instance,template)
        self << {:instance => instance, :template => template}
      end
      def find_template(instance)
      end
    end
  end
end; end
