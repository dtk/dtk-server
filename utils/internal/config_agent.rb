module XYZ
  class ConfigAgent
    def self.parse_given_module_directory(type,dir)
      load(type).parse_given_module_directory(dir)
    end
    def self.parse_given_filename(type,filename)
      load(type).parse_given_filename(filename)
    end
    def self.parse_given_file_content(type,file_path,file_content)
      load(type).parse_given_file_content(file_path,file_content)
    end

    #TODO: make private and wrap as ConfigAgent method like do for parse
    def self.load(type)
      return nil unless type
      return Agents[type] if Agents[type]
      klass = self
      begin
        Lock.synchronize do
          r8_nested_require("config_agent","adapters/#{type}")
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

    Lock = Mutex.new
    Agents = Hash.new

    class ParseError < Error
      attr_reader :msg, :filename, :file_asset_id, :line
      def initialize(msg,file_path=nil,line=nil)
        @msg = msg
        if filename = get_filename(file_path)
          @filename = filename
          @repo = get_repo(file_path)
          @line = line
        end
      end

      def set_file_asset_id!(model_handle)
        return unless @filename and @repo
        sp_hash = {
          :cols => [:id],
          :filter => [:eq,:display_name,@repo]
        }
        return unless impl = Model.get_obj(model_handle.createMH(:implementation),sp_hash)
        sp_hash = {
          :cols => [:id],
          :filter => [:eq,:path,@filename]
        }        
        file = impl.get_children_objs(:file_asset,sp_hash).first
        @file_asset_id = file[:id] if file
      end

      def to_s()
        [:msg, :filename, :file_asset_id, :line].map do |k|
          val = send(k)
          "#{k}=#{val}" if val
        end.compact.join("; ")
      end
      private
      def get_filename(file_path)
        return nil unless file_path
        if file_path =~ Regexp.new("#{R8::EnvironmentConfig::ImportTestBaseDir}/[^/]+/(.+$)")
          $1
        end
      end
      def get_repo(file_path)
        return nil unless file_path
        if file_path =~ Regexp.new("#{R8::EnvironmentConfig::ImportTestBaseDir}/([^/]+)")
          $1
        end
      end
    end
    class ParseErrors < Error
      attr_reader :error_list
      def initialize()
        @error_list = Array.new
      end
      def add(error_info)
        if error_info.kind_of?(ParseError)
          @error_list << error_info
        elsif error_info.kind_of?(ParseErrors)
          @error_list += error_info.error_list
        end
        self
      end
      def set_file_asset_ids!(model_handle)
        @error_list.each{|e|e.set_file_asset_id!(model_handle)}
      end
    end
  end

  module ConfigAgentAdapter
  end
end
