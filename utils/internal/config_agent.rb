module DTK
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

    def self.parse_external_ref?(type,impl_obj)
      processor = load(type)
      if processor.respond_to?('parse_external_ref?'.to_sym)
        processor.parse_external_ref?(impl_obj)
      end
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

    class ParseError < ErrorUsage
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
        #TODO: stub
        file_path
      end
      def get_repo(file_path)
        #TODO: stub
        file_path
      end
    end
    class ParseErrors < ErrorUsage
      attr_reader :error_list
      def initialize(config_agent_type)
        @config_agent_type = config_agent_type
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
      def to_s()
        preamble = 
          if @config_agent_type == :puppet
            "Puppet manifest parse error"
          else
            "Parse error"
          end
        preamble << ((@error_list.size > 1) ? "s:\n" : ":\n")

        "#{preamble}  #{@error_list.map{|e|e.to_s}.join('\n  ')}"
      end
    end
  end

  module ConfigAgentAdapter
  end
end
