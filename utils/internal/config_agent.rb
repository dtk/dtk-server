module XYZ
  class ConfigAgent
    def self.parse_given_filename(type,filename)
      load(type).parse_given_filename(filename)
    end
    def self.parse_given_file_content(type,file_content)
      load(type).parse_given_file_content(file_content)
    end

    def self.load(type)
      return nil unless type
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
