module R8
  module Client
    class ViewProcessor
      class << self
        include Aux
        def render(command_class,ruby_obj,type)
          command = snake_form(command_class)
          adapter = get_adapter(type,command)
          if ruby_obj.kind_of?(Hash)
            adapter.render(ruby_obj)
          elsif ruby_obj.kind_of?(Array)
            ruby_obj.map{|el|render(command_class,el,type)}
          else
            raise Error.new("ruby_obj has unexepected type")
          end
        end
       private
        def get_adapter(type,command)
          cached = (AdapterCache[type]||{})[command]
          return cached if cached
          r8_nested_require("view_processor",type)
          klass = R8::Client.const_get "ViewProc#{cap_form(type)}" 
          AdapterCache[type] ||= Hash.new
          AdapterCache[type][command] = klass.new(type,command)
        end
        AdapterCache = Hash.new
      end
    end
    module ViewMeta
    end
  end
end
