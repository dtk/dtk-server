module DTK; class ComponentDSL
  class IncrementalGenerator
    def self.generate(aug_object)
      klass(aug_object).new().generate(ObjectWrapper.new(aug_object))
    end

    def self.merge_fragment_into_full_hash!(full_hash,object_class,fragment,context={})
      klass(object_class).new().merge_fragment!(full_hash,fragment,context)
      full_hash
    end

   private
    def self.klass(object_or_class)
      klass = (object_or_class.kind_of?(Class) ? object_or_class : object_or_class.class)
      class_last_part = klass.to_s.split('::').last
      ret = nil
      begin 
        ret = const_get class_last_part
       rescue
        raise Error.new("Generation of type (#{class_last_part}) not treated")
      end
      ret
    end

    def set?(key,content,obj)
      val = obj[key]
      unless val.nil?
        content[key.to_s] = val 
      end
    end

    def component_fragment(full_hash,component_template)
      unless component_type = component_template && component_template.get_field?(:component_type)
        raise Error.new("The method merge_fragment needs the context :component_template")
      end
      component().get_fragment(full_hash,component_type)
    end

    class ObjectWrapper
      attr_reader :object
      def initialize(object)
        @object = object
      end
      def required(key)
        ret = @object[key]
        if ret.nil?
          raise Error.new("Expected that object of type (#{@object}) has non null key (#{key})")
        end
        ret
      end
      def [](key)
        @object[key]
      end
    end
  end
end; end
