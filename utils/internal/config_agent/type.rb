module DTK
  class ConfigAgent
    module Type
      module Symbol
        All = [:puppet,:chef,:dtk_provider,:serverspec,:test,:node_module]
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
