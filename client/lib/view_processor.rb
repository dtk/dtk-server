module R8
  module Client
    class ViewProcessor
      class << self
        def render(hash,type)
          #TODO: hard wired command; can get it from looking at called
          command = "task"
          adapter = get_adapter(type,command)
          adapter.render(hash)
        end
       private
        def get_adapter(type,command)
          cached = (AdapterCache[type]||{})[command]
          return cached if cached
          r8_nested_require("view_processor",type)
          klass = R8::Client.const_get "ViewProc#{cap_form(type)}" 
          AdapterCache[type] ||= Hash.new
          AdapterCache[type][command] = klass.new(get_meta(type,command))
        end
        AdapterCache = Hash.new
        def get_meta(type,command)
          r8_require("../views/#{command}/#{type}")
          R8::Client::ViewMeta.const_get cap_form(type)
        end

        def cap_form(x)
          x.to_s.split("_").map{|t|t.capitalize}.join("")
        end
      end
     protected
      def initialize(meta)
        @meta = meta
      end
     private
      attr_reader :meta
    end
    module ViewMeta
    end
  end
end
