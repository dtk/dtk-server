module DTK
  class ConfigAgent
    module Adapter
      def self.load(type)
        return nil unless type
        return Agents[type] if Agents[type]
        klass = self
        begin
          Lock.synchronize do
            r8_nested_require("adapter",type)
          end
          klass = const_get type.to_s.capitalize
        rescue LoadError
          raise Error.new("cannot find config agent adapter for type (#{type})")
        end
        Agents[type] = klass.new()
      end
      Lock = Mutex.new
      Agents = Hash.new
    end
  end
end
