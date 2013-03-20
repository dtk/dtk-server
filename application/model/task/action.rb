module DTK; class Task
  class Action < HashObject 
    r8_nested_require('action','on_node')
    r8_nested_require('action','on_component')
    def type()
      Aux.underscore(Aux.demodulize(self.class.to_s)).to_sym
    end

    #implemented functions
    def long_running?()
      nil
    end

    #returns [adapter_type,adapter_name], adapter name optional in which it wil be looked up from config
    def ret_command_and_control_adapter_info()
     nil
    end

    class Result < HashObject
      def initialize(hash={})
        super(hash)
        self[:result_type] = Aux.demodulize(self.class.to_s).downcase
      end

      class Succeeded < self
        def initialize(hash={})
          super(hash)
        end
      end
      class Failed < self
        def initialize(error)
          super()
          self[:error] =  error.to_hash
        end
      end
      class Cancelled < self
        def initialize(hash={})
          super(hash)
        end
      end
    end
  end
end; end
