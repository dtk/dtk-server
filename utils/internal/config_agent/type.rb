module DTK
  class ConfigAgent
    module Type
      def self.is_a?(config_agent_type, type_or_types) 
        if type_or_types.kind_of?(Array)
          type_or_types.find { |type| is_this_type?(config_agent_type, type) }
        else
          is_this_type?(config_agent_type, type_or_types)
        end
      end

      private
      
      def self.is_this_type?(config_agent_type, type)
        if config_agent_type && (config_agent_type.to_sym == Symbol.send(type))
          config_agent_type.to_sym
        end
      end

      module Symbol
        All = [:puppet, :dtk_provider, :no_op, :ruby_function, :chef, :serverspec, :test, :node_module]
        Default = :puppet
        All.each do |type|
          class_eval("def self.#{type}();:#{type};end")
        end
      end
      def self.default_symbol
        Symbol::Default
      end
    end
  end
end
