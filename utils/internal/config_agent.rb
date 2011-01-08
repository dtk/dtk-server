module XYZ
  class ConfigAgent
    def self.load(type)
      return Agents[type] if Agents[type]
      klass = self
      begin
        Lock.synchronize do
          require File.expand_path("#{UTILS_DIR}/internal/config_agent/adapters/#{type}", File.dirname(__FILE__))
        end
        klass = XYZ::ConfigAgentAdapter.const_get type.to_s.capitalize
       rescue LoadError
        Log.error("cannot find config agent adapter; loading null config agent class")
      end
      Agents[type] = klass.new()
    end

    #common functions accross config agents
    def pbuilderid(node)
      (node[:external_ref]||{})[:instance_id]
    end

    def node_name(node)
      (node[:external_ref]||{})[:instance_id]
    end

    private
     Lock = Mutex.new
     Agents = Hash.new
  end
  module ConfigAgentAdapter
  end
end
