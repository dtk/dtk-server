module DTKModule
  module DTK
    class Settings < ::Hash
      def initialize(settings_hash = {})
        super()
        replace(settings_hash)
      end
      private :initialize
      
      def self.settings_from_attributes(attributes)
        required_settings_hash = required.inject({}) { |h, k| h.merge(k => attributes.value(k)) }
        all_settings_hash = optional.inject(required_settings_hash) do |h, k|
          value = attributes.value?(k)
          value.nil? ? h : h.merge(k => value)
        end 
        new(all_settings_hash)
      end

      def non_nil_dynamic_attributes
        dynamic.inject({}) do |h, attr|
          val = self[attr]
          val.nil? ? h : h.merge(attr => val)
        end
      end

      def dynamic_attributes
        dynamic.inject({}) { |h, attr| h.merge(attr => self[attr]) }
      end

      # method missing to handle Settings#attribute and Settings#dynamic= 
      def method_missing(method, *args)
        if all_attributes.include?(method)
          attribute = method
          val = self[attribute]
          # This is redundant check because Settings.settings should take care of it
          fail "Attribute '#{attribute}' must be non nil" if required.include?(attribute) and val.nil?
          val
        elsif dynamic_assignment_methods.include?(method)
          fail "Method '#{method}' should only take a single argument" unless args.size == 1
          val = args.first
          self[dynamic_assignment_attribute(method)] = val
          val
        else
          super 
        end
       end

      def respond_to?(method)
        all_attributes.include?(method) or dynamic_assignment_methods.include?(method) or super
      end

      private

      def self.dynamic_assignment_methods
        @dynamic_assignment_methods ||= dynamic.map { |attr| "#{attr}=".to_sym } 
      end
      def dynamic_assignment_methods
        self.class.dynamic_assignment_methods
      end

      def dynamic_assignment_attribute(method)
        if method.to_sym =~ /(^.+)=$/
          $1.to_sym
        else
          fail "The term '#{method}' has an unexpecated form for a dynamic assignment method" 
        end
      end

      def self.required
        self::REQUIRED
      end
      def required
        self.class.required
      end

      def self.optional
        self::OPTIONAL
      end
      def optional
        self.class.optional
      end

      def self.dynamic
        self::DYNAMIC
      end
      def dynamic
        self.class.dynamic
      end

      def self.all_attributes
        @all_attributes ||= dynamic + required + optional
      end
      def all_attributes
        self.class.all_attributes
      end

      # defaults if REQUIRED, OPTIONAL, or DYNAMIC not specified
      DYNAMIC = OPTIONAL = REQUIRED = []
    end
  end
end
