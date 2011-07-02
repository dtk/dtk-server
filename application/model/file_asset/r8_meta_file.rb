module XYZ
  module FileAssetR8MetaFile
    class R8MetaFile
      #creates if file_obj is a r8meta file
      def self.isa?(file_obj,content)
        return nil unless file_obj[:path] =~ /^r8meta\.([a-z]+)\.([a-z]+$)/
        config_agent_type = $1.to_sym
        file_extension = $2
        format_type = ExtensionToType[file_extension]
        raise Error.new("illegal fiel extension #{file_extension}") unless file_extension
        self.new(config_agent_type,format_type,content)
      end
      ExtensionToType = {
        "yml" => :yaml
      }

      def initialize(config_agent_type,format_type,content)
        @config_agent_type = config_agent_type
        @format_type = format_type
        @content = content
      end
      def process()
        if @format_type == :yaml
        else
          raise Error.new("cannot treat format type #{format_type}")
        end
      end
    end
  end
end
