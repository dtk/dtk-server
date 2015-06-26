module DTK; class Task; class Template
  class Action
    class ComponentAction < self
      r8_nested_require('component_action','in_component_group')
      include InComponentGroupMixin

      def initialize(component,opts={})
        unless component[:node].kind_of?(Node)
          raise Error.new("ComponentAction.new must be given component argument with :node key")
        end
        super(opts)
        @component = component
      end
      private :initialize

      def method_missing(name,*args,&block)
        @component.send(name,*args,&block)
      end
      def respond_to?(name)
        @component.respond_to?(name) || super
      end

      def node()
        @component[:node]
      end
      def node_id()
        if node = node()
          node.get_field?(:id)
        end
      end
      def node_name()
        if node = node()
          node.get_field?(:display_name)
        end
      end

      def action_defs()
        self[:action_defs]||[]
      end

      def match_action?(action)
        action.kind_of?(self.class) and 
        node_name() == action.node_name and 
        component_type() == action.component_type()
      end

      def match?(node_name,component_name_ref=nil)
         ret = 
          if node_name() == node_name
            if component_name_ref.nil?
              true
            else
              # strip off node_name prefix if it exists
              # need to handle cases like apt::ppa[ppa:chris/node.js]
              component_name_ref_x = component_name_ref.gsub(/^[^\[]+\//,'')
              component_name_ref_x ==  serialization_form(:no_node_name_prefix => true)
            end
          end
        !!ret
      end

      def match_component_ref?(component_type,title=nil)
        component_type == component_type(:without_title=>true) and
          (title.nil? or title == component_title?())
      end

      def serialization_form(opts={})
        if filter = opts[:filter]
          if filter.keys == [:source]
            return nil unless filter[:source] == source_type()
          else
            raise Error.new("Not treating filter of form (#{filter.inspect})")
          end
        end
        node_name = ((!opts[:no_node_name_prefix]) && component()[:node][:display_name])
        component_type = component_type()
        node_name ? "#{node_name}/#{component_type}" : component_type
      end
        
      def source_type()
        ret = (@component[:source]||{})[:type]
        ret && ret.to_sym
      end

      def assembly_idh?()
        if source_type() == :assembly
          @component[:source][:object].id_handle()
        end
      end

      def component_type(opts={})
        cmp_type = Component.component_type_print_form(@component.get_field?(:component_type))
        unless opts[:without_title] 
          if title = component_title?()
            cmp_type = ComponentTitle.print_form_with_title(cmp_type,title)
          end
        end
        cmp_type
      end

      def component_title?()
        @component[:title]
      end

    end
  end
end; end; end
