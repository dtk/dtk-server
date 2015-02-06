module DTK; class Task; class Template
  class Action
    class WithMethod < self
      # opts can have keys
      # :method_name
      def initialize(action,opts={})
        @action = action
        @method_name = opts[:method_name] || DefaultMethodName
      end
      DefaultMethodName = :create

      def method_missing(name,*args,&block)
        @action.send(name,*args,&block)
      end
      def respond_to?(name)
        @action.respond_to?(name) || super
      end

      # returns [component_name_ref,method_name]
      def self.parse(serialized_item)
        unless serialized_item.kind_of?(String)
          raise_action_ref_error(serialized_item)
        end
        if info = has_explicit_method?(serialized_item)
          [info[:component_name_ref],info[:method_name]]
        else
          [serialized_item,DefaultMethodName]
        end
      end

      private
      # returns hash with keys :component_name_ref,:method_name
      # if has explicit method otherwise returns nil
      # explicit form is 
      #   component.method_name, or
      #   component[title].method_name
      # complication is that title can have a '.' in it
      def self.has_explicit_method?(serialized_item)
        # case on whether has title
        if serialized_item =~ /(^[^\[]+)\[([^\]]+)\](.*$)/
          cmp_with_title = "#{$1}[#{$2}]"
          dot_method = $3
          if dot_method.empty?
            nil
          elsif dot_method =~ /^\.(.+$)/
            method = $1
            {:component_name_ref => cmp_with_title,:method_name => method}
          else
            raise_action_ref_error(serialized_item)
          end
        else
          # no title
          split = serialized_item.split('.')
          case split.size
           when 1 
            nil
           when 2
            {:component_name_ref => split[0], :method_name => split[1]}
          else
            raise_action_ref_error(serialized_item)
          end
        end
      end

      def self.raise_action_ref_error(serialized_item)
        raise ParsingError.new("The action reference (#{serialized_item.inspect}) is ill-formed")
      end
    end
  end
end; end; end
