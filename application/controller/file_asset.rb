module XYZ
  class File_assetController < Controller
    helper :i18n_string_mapping

    def get(id)
      file_asset = get_object_by_id(id)
      file_asset[:name] = file_asset[:file_name]

      return {:data=>file_asset}
    end
  end

end