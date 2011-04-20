module XYZ
  class FileAsset < Model
    #model apis
    def self.load_and_create_file_asset(parent_idh,file_name,file_content_path)
      file_content = File.open(file_content_path){|f|f.read} 
      parent_id = parent_idh.get_id()
      parent_col = DB.parent_field(parent_idh[:model_name],:file_asset)

      create_row = {
        :ref => file_name,
        :file_name => file_name,
        :display_name => file_name,
        parent_col => parent_id,
        :content => file_content
      }

      file_asset_mh = parent_idh.create_childMH(:file_asset)
      create_from_rows(file_asset_mh,[create_row])
    end
  end
end

