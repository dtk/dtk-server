module R8
  module Client
    class ViewProcessor
      class << self
        def render(hash,type)
          #TODO: hard wired command; can get it from looking at called
          command = "task"
          klass = load_view_adapter_class(type)
          meta = get_meta(type,command)
          klass.render(hash,meta)
        end
       private
        def load_view_adapter_class(type)
          r8_nested_require("view_processor",type)
          R8::Client.const_get "ViewProc#{cap_form(type)}" 
        end
        def get_meta(type,command)
          cached = (MetaCache[command]||{})[type]
          return cached if cached
          r8_require("../views/#{command}/#{type}")
          MetaCache[command] ||= Hash.new
          MetaCache[command][type] = R8::Client::ViewMeta.const_get cap_form(type)
        end
        MetaCache = Hash.new
        def cap_form(x)
          x.to_s.split("_").map{|t|t.capitalize}.join("")
        end
      end
    end
    module ViewMeta
    end
  end
end
