module DTK; class Task; class Template
  class Action
    # This represents an action with an explicit method, as opposed to other action terms, which just have component reference
    class WithMethod < self
      r8_nested_require('with_method', 'params')

      def initialize(action, action_def)
        @action = action
        @method = ActionMethod.new(action_def)
      end

      def action_method?
        @method
      end

      def method_missing(name, *args, &block)
        @action.send(name, *args, &block)
      end

      def respond_to?(name)
        @action.respond_to?(name) || super
      end

      ParseStruct = Struct.new(:component_name_ref,:method_name,:params)
      # returns ParseStruct
      #  method_name and params can be nil
      def self.parse(serialized_item)
        raise_action_ref_error(serialized_item) unless serialized_item.is_a?(String)
        has_explicit_method?(serialized_item) || ParseStruct.new(serialized_item, nil, nil)
      end

      private

      # returns ParseStruct if has explicit method otherwise returns nil
      # explicit form is
      #   component.method_name, or
      #   component[title].method_name
      # complication is that title can have a '.' in it
      def self.has_explicit_method?(serialized_item)
        has_explicit_method__with_title?(serialized_item) || has_explicit_method__without_title?(serialized_item)
      end

      def self.has_explicit_method__with_title?(serialized_item)
        ret = nil
        return ret unless serialized_item =~ /(^[^\[]+)\[([^\]]+)\](.*$)/
        cmp_with_title = "#{Regexp.last_match(1)}[#{Regexp.last_match(2)}]"
        dot_method = Regexp.last_match(3)
        if dot_method.empty?
          nil
        elsif dot_method =~ /^\.(.+$)/
          method_name, params = split_method_name_and_params(Regexp.last_match(1))
          ParseStruct.new(cmp_with_title, method_name, params)
        else
          raise_action_ref_error(serialized_item)
        end
      end

      def self.has_explicit_method__without_title?(serialized_item)
        split = serialized_item.split('.')
        case split.size
        when 1
          nil
        when 2
          component_name_ref = split[0]
          method_name, params = split_method_name_and_params(split[1])
          ParseStruct.new(component_name_ref, method_name, params)
        else
          raise_action_ref_error(serialized_item)
        end
      end

      # returns method_name, params
      # params can be nil
      def self.split_method_name_and_params(serialized_item)
        if serialized_item =~ /(^[^ ]+)[ ]+(.+$)/
          [Regexp.last_match(1), Params.parse(Regexp.last_match(2))]
        else
          [serialized_item, nil]
        end
      end

      def self.raise_action_ref_error(serialized_item)
        fail ParsingError.new("The action reference (#{serialized_item.inspect}) is ill-formed")
      end
    end
  end
end; end; end
