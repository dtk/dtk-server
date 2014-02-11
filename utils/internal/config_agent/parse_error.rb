module DTK
  class ConfigAgent
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
  end
end
