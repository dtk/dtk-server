module DTK; class Task; class Template
  class Action
    def self.create(object)
      if object.kind_of?(Component)
        ComponentAction.new(object)
      else
        raise Error.new("Not yet implemented treatment of action of type {#{object.class.to_s})")
      end
    end

    attr_accessor :index

    def method_missing(name,*args,&block)
      @action.send(name,*args,&block)
    end
    def respond_to?(name)
      @action.respond_to?(name) || super
    end
    
   private
    attr_accessor :action
    def initialize(action,index=nil)
      @action = action
      @index = index
    end

    class ComponentAction < self
      def initialize(component,index=nil)
        unless component[:node].kind_of?(Node)
          raise Error.new("ComponentAction.new must be given component argument with :node key")
        end
        super(component,index)
      end

      def in_component_group(component_group_num)
        InComponentGroup.new(action,index,component_group_num)
      end

      #overwritten by InComponentGroup
      def component_group_num()
        nil
      end

      def node()
        component[:node]
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
              #strip off node_name prefix if it exists
              component_name_ref_x = component_name_ref.split("/").last
              component_name_ref_x ==  serialization_form(:no_node_name_prefix => true)
            end
          end
        !!ret
      end

      def match_component_type?(component_type)
        component_type == component_type(:without_title=>true)
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
        ret = (component()[:source]||{})[:type]
        ret && ret.to_sym
      end

      def assembly_idh?()
        if source_type() == :assembly
          component()[:source][:object].id_handle()
        end
      end

      def component_type(opts={})
        cmp = component()
        cmp_type = Component.component_type_print_form(cmp.get_field?(:component_type))
        unless opts[:without_title] 
          if title = cmp[:title]
            cmp_type = ComponentTitle.print_form_with_title(cmp_type,title)
          end
        end
        cmp_type
      end

     private
      def component()
        @action
      end

      class InComponentGroup < self
        attr_reader :component_group_num
        def initialize(component,index,component_group_num)
          super(component,index)
          @component_group_num = component_group_num
        end
      end
      
    end
  end
end; end; end
