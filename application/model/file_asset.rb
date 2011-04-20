module XYZ
  class FileAsset < Model
    #model apis
    def self.load_and_create_file_asset(parent_idh,file_name,file_content_path)
      file_content = File.open(file_content_path){|f|f.read} 
      nil
    end
  end
end

