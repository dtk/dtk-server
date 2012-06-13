module DTK
  module Client
    class ViewProcessor
      class << self
        include Aux
        def render(command_class,ruby_obj,type,adapter=nil)
          adapter ||= get_adapter(type,command_class)
          if ruby_obj.kind_of?(Hash)
            adapter.render(ruby_obj)
          elsif ruby_obj.kind_of?(Array)
            ruby_obj.map{|el|render(command_class,el,type,adapter)}
          else
            raise Error.new("ruby_obj has unexepected type")
          end
        end

        def get_adapter(type,command_class)
          cached = (AdapterCache[type]||{})[command_class]
          return cached if cached
          dtk_nested_require("view_processor",type)
          klass = DTK::Client.const_get "ViewProc#{cap_form(type)}" 
          AdapterCache[type] ||= Hash.new
          AdapterCache[type][command_class] = klass.new(type,command_class)
        end
        AdapterCache = Hash.new
      end
     private
      def initialize(type,command_class)
        @command_class = command_class
      end

      def get_meta(type,command_class)
        ret = nil
        command = snake_form(command_class)
        begin
          dtk_require("../views/#{command}/#{type}")
          ret = DTK::Client::ViewMeta.const_get cap_form(type)
         rescue Exception => e
          ret = failback_meta(command_class.respond_to?(:pretty_print_cols) ? command_class.pretty_print_cols() : [])
        end
        ret
      end
    end
    module ViewMeta
    end
  end
end
